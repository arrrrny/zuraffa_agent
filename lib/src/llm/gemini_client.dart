// Ported from dart_agent_core (MIT License, Copyright (c) 2024-2026
// contributors) — see NOTICE. dart_agent_core is NOT a dependency of this
// package (spec 007 FR-007, constitution VIII): the behavior is re-implemented
// in-tree per specs/007-llm-provider-clients/spec.md with this attribution
// retained.

import 'dart:convert';

import '../types.dart';
import 'llm_client.dart';
import 'llm_clock.dart';
import 'llm_transport.dart';
import 'retry.dart';

/// Google Generative AI (Gemini) client (spec 007 US3) with JSON-line
/// streaming and function calling.
class GeminiClient implements LlmClient {
  @override
  final String providerName;
  final LlmTransport transport;
  final String baseUrl;
  @override
  final String model;
  final String? apiKey;
  final RetryConfig retryConfig;
  final LlmClock clock;
  final int Function(int coreDelayMs)? jitter;

  GeminiClient({
    this.providerName = 'gemini',
    required this.transport,
    required this.baseUrl,
    required this.model,
    this.apiKey,
    this.retryConfig = const RetryConfig(),
    this.clock = const SystemLlmClock(),
    this.jitter,
  });

  @override
  Future<LlmResponse> generate(LlmRequest request) async {
    final response = await sendWithRetry(
      transport: transport,
      request: _httpRequest(':generateContent', jsonEncode(_buildBody(request))),
      config: retryConfig,
      clock: clock,
      provider: providerName,
      jitter: jitter,
    );
    return _parseGenerate(response.body);
  }

  @override
  Stream<LlmResponseChunk> stream(LlmRequest request) async* {
    final response = await openStreamWithRetry(
      transport: transport,
      request: _httpRequest(':streamGenerateContent?alt=sse', jsonEncode(_buildBody(request))),
      config: retryConfig,
      clock: clock,
      provider: providerName,
      jitter: jitter,
    );

    final toolCalls = <LlmToolCall>[];
    var finishReason = 'stop';
    LlmUsage? usage;

    await for (final line in response.lines) {
      if (line.isEmpty || line.startsWith(':')) continue;
      String payload = line;
      if (line.startsWith('data:')) {
        payload = line.substring(5).trim();
      }
      final Map<String, dynamic> event;
      try {
        event = jsonDecode(payload) as Map<String, dynamic>;
      } on FormatException {
        continue; // Skip malformed lines without killing the stream.
      }

      final candidates = (event['candidates'] as List?) ?? const [];
      for (final candidate in candidates) {
        final c = candidate as Map;
        final content = (c['content'] as Map?) ?? const {};
        final parts = (content['parts'] as List?) ?? const [];
        for (final part in parts) {
          final p = part as Map;
          if (p['text'] is String && (p['text'] as String).isNotEmpty) {
            yield LlmResponseChunk(content: p['text'] as String);
          }
          final functionCall = p['functionCall'] as Map?;
          if (functionCall != null) {
            toolCalls.add(LlmToolCall(
              id: (functionCall['id'] as String?) ?? 'call_${toolCalls.length}',
              name: (functionCall['name'] as String?) ?? '',
              arguments: _asMap(functionCall['args']),
            ));
          }
        }
        final reason = c['finishReason'] as String?;
        if (reason != null) {
          finishReason = _normalizeFinishReason(reason) ?? finishReason;
        }
      }
      if (event['usageMetadata'] is Map) {
        usage = _parseUsage(event['usageMetadata']);
      }
    }

    if (toolCalls.isNotEmpty) {
      yield LlmResponseChunk(toolCalls: List.unmodifiable(toolCalls));
    }
    yield LlmResponseChunk(
      usage: usage,
      isComplete: true,
      finishReason: finishReason,
    );
  }

  @override
  Future<void> close() async {}

  LlmHttpRequest _httpRequest(String action, String body) => LlmHttpRequest(
        uri: Uri.parse(
            '$baseUrl/models/$model$action'),
        headers: {
          'x-goog-api-key': ?apiKey,
          'content-type': 'application/json',
        },
        body: body,
      );

  Map<String, dynamic> _buildBody(LlmRequest request) => {
        if (request.systemPrompt != null)
          'systemInstruction': {
            'parts': [
              {'text': request.systemPrompt},
            ],
          },
        'contents': [
          for (final message in request.messages) _messageToContent(message),
        ],
        if (request.tools != null)
          'tools': [
            {
              'functionDeclarations': [
                for (final tool in request.tools!)
                  {
                    'name': tool.name,
                    'description': tool.description,
                    'parameters': tool.parameters,
                  },
              ],
            },
          ],
        if (request.temperature != null || request.maxTokens != null)
          'generationConfig': {
            if (request.temperature != null)
              'temperature': request.temperature,
            if (request.maxTokens != null)
              'maxOutputTokens': request.maxTokens,
          },
      };

  Map<String, dynamic> _messageToContent(AgentMessage message) {
    switch (message) {
      case UserMessage():
        return {
          'role': 'user',
          'parts': [
            for (final block in message.content) _blockToPart(block),
          ],
        };
      case AssistantMessage():
        return {
          'role': 'model',
          'parts': [
            for (final block in message.content) _blockToPart(block),
          ],
        };
      case ToolResultMessage():
        return {
          'role': 'user',
          'parts': [
            {
              'functionResponse': {
                'name': message.toolName,
                'response': {'result': message.content},
              },
            },
          ],
        };
      case CustomMessage():
        return {
          'role': 'user',
          'parts': [
            {
              'text':
                  '[custom:${message.messageType}] ${jsonEncode(message.payload)}',
            },
          ],
        };
    }
  }

  Map<String, dynamic> _blockToPart(ContentBlock block) {
    switch (block) {
      case TextBlock():
        return {'text': block.text};
      case ImageBlock():
      case AudioBlock():
      case DocumentBlock():
        return {
          'inlineData': {
            'mimeType': switch (block) {
              ImageBlock(:final mimeType) => mimeType,
              AudioBlock(:final mimeType) => mimeType,
              DocumentBlock(:final mimeType) => mimeType,
              _ => 'application/octet-stream',
            },
            'data': switch (block) {
              ImageBlock(:final data) => data,
              AudioBlock(:final data) => data,
              DocumentBlock(:final data) => data,
              _ => '',
            },
          },
        };
      case ToolCallBlock():
        return {
          'functionCall': {'name': block.name, 'args': block.arguments},
        };
      default:
        return {'text': block.toString()};
    }
  }

  LlmResponse _parseGenerate(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final candidates = (json['candidates'] as List?) ?? const [];
    final text = StringBuffer();
    final toolCalls = <LlmToolCall>[];
    var finishReason = 'stop';
    if (candidates.isNotEmpty) {
      final candidate = candidates.first as Map;
      finishReason = _normalizeFinishReason(
              candidate['finishReason'] as String?) ??
          'stop';
      final content = (candidate['content'] as Map?) ?? const {};
      final parts = (content['parts'] as List?) ?? const [];
      for (final part in parts) {
        final p = part as Map;
        if (p['text'] is String) text.write(p['text'] as String);
        final functionCall = p['functionCall'] as Map?;
        if (functionCall != null) {
          toolCalls.add(LlmToolCall(
            id: (functionCall['id'] as String?) ?? 'call_${toolCalls.length}',
            name: (functionCall['name'] as String?) ?? '',
            arguments: _asMap(functionCall['args']),
          ));
        }
      }
    }
    return LlmResponse(
      content: text.toString(),
      toolCalls: toolCalls,
      usage: _parseUsage(json['usageMetadata']),
      finishReason: finishReason,
    );
  }

  static LlmUsage _parseUsage(dynamic metadata) {
    if (metadata is! Map) return const LlmUsage();
    return LlmUsage(
      inputTokens: (metadata['promptTokenCount'] as num?)?.toInt() ?? 0,
      outputTokens: (metadata['candidatesTokenCount'] as num?)?.toInt() ?? 0,
      cachedTokens: (metadata['cachedContentTokenCount'] as num?)?.toInt() ?? 0,
      thoughtTokens: (metadata['thoughtsTokenCount'] as num?)?.toInt() ??
          (metadata['thoughtTokenCount'] as num?)?.toInt() ??
          0,
    );
  }

  static Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const {};
  }

  static String? _normalizeFinishReason(String? reason) {
    switch (reason) {
      case 'STOP':
        return 'stop';
      case 'MAX_TOKENS':
        return 'length';
      case 'SAFETY':
      case 'RECITATION':
        return 'content_filter';
      case 'MALFORMED_FUNCTION_CALL':
        // Surfaced verbatim (lowercased) so callers can react to it (AC-7).
        return 'malformed_function_call';
      default:
        return reason?.toLowerCase();
    }
  }
}
