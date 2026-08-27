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

/// Anthropic Messages API client (spec 007 US2) with thinking, content
/// blocks, and tool use.
class AnthropicClient implements LlmClient {
  static const apiVersion = '2023-06-01';

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

  AnthropicClient({
    this.providerName = 'anthropic',
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
      request: _httpRequest(jsonEncode(_buildBody(request))),
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
      request: _httpRequest(jsonEncode(_buildBody(request, stream: true))),
      config: retryConfig,
      clock: clock,
      provider: providerName,
      jitter: jitter,
    );

    final toolBuffers = <int, _AnthropicToolBuffer>{};
    var finishReason = 'stop';
    LlmUsage usage = const LlmUsage();

    await for (final line in response.lines) {
      if (line.isEmpty || line.startsWith(':')) continue;
      if (!line.startsWith('data:')) continue;
      final payload = line.substring(5).trim();
      final Map<String, dynamic> event;
      try {
        event = jsonDecode(payload) as Map<String, dynamic>;
      } on FormatException {
        continue;
      }
      switch (event['type'] as String? ?? '') {
        case 'message_start':
          final message = (event['message'] as Map?) ?? const {};
          usage = usage.copyWith(
            inputTokens:
                ((message['usage'] as Map?)?['input_tokens'] as num?)
                        ?.toInt() ??
                    usage.inputTokens,
          );
        case 'content_block_start':
          final block = (event['content_block'] as Map?) ?? const {};
          if (block['type'] == 'tool_use') {
            toolBuffers[(event['index'] as num?)?.toInt() ?? 0] =
                _AnthropicToolBuffer(
              id: (block['id'] as String?) ?? '',
              name: (block['name'] as String?) ?? '',
            );
          }
        case 'content_block_delta':
          final delta = (event['delta'] as Map?) ?? const {};
          final index = (event['index'] as num?)?.toInt() ?? 0;
          switch (delta['type'] as String? ?? '') {
            case 'text_delta':
              final text = delta['text'] as String?;
              if (text != null && text.isNotEmpty) {
                yield LlmResponseChunk(content: text);
              }
            case 'thinking_delta':
              final thinking = delta['thinking'] as String?;
              if (thinking != null && thinking.isNotEmpty) {
                yield LlmResponseChunk(thinking: thinking);
              }
            case 'input_json_delta':
              final buffer = toolBuffers[index];
              if (buffer != null) {
                buffer.arguments += (delta['partial_json'] as String?) ?? '';
              }
          }
        case 'content_block_stop':
          final buffer = toolBuffers.remove((event['index'] as num?)?.toInt() ?? 0);
          if (buffer != null) {
            yield LlmResponseChunk(toolCalls: [
              LlmToolCall(
                id: buffer.id,
                name: buffer.name,
                arguments: _parseArguments(buffer.arguments),
              ),
            ]);
          }
        case 'message_delta':
          final delta = (event['delta'] as Map?) ?? const {};
          finishReason =
              _normalizeStopReason(delta['stop_reason'] as String?) ??
                  finishReason;
          final outTokens =
              ((event['usage'] as Map?)?['output_tokens'] as num?)?.toInt();
          if (outTokens != null) {
            usage = usage.copyWith(outputTokens: outTokens);
          }
        case 'message_stop':
          yield LlmResponseChunk(
            usage: usage,
            isComplete: true,
            finishReason: finishReason,
          );
          return;
      }
    }
    // Stream ended without message_stop: finalize anyway.
    yield LlmResponseChunk(
      usage: usage,
      isComplete: true,
      finishReason: finishReason,
    );
  }

  @override
  Future<void> close() async {}

  LlmHttpRequest _httpRequest(String body) => LlmHttpRequest(
        uri: Uri.parse('$baseUrl${baseUrl.endsWith('/') ? '' : '/'}messages'),
        headers: {
          'x-api-key': ?apiKey,
          'anthropic-version': apiVersion,
          'content-type': 'application/json',
        },
        body: body,
      );

  Map<String, dynamic> _buildBody(LlmRequest request, {bool stream = false}) => {
        'model': model,
        'max_tokens': request.maxTokens ?? 4096,
        if (request.systemPrompt != null) 'system': request.systemPrompt,
        'messages': [for (final m in request.messages) _messageToJson(m)],
        if (request.tools != null)
          'tools': [
            for (final tool in request.tools!)
              {
                'name': tool.name,
                'description': tool.description,
                'input_schema': tool.parameters,
              },
          ],
        if (request.temperature != null) 'temperature': request.temperature,
        if (stream) 'stream': true,
      };

  Map<String, dynamic> _messageToJson(AgentMessage message) {
    switch (message) {
      case UserMessage():
        return {
          'role': 'user',
          'content': [
            for (final block in message.content) _contentBlock(block),
          ],
        };
      case AssistantMessage():
        final content = <Map<String, dynamic>>[];
        for (final block in message.content) {
          switch (block) {
            case TextBlock():
              content.add({'type': 'text', 'text': block.text});
            case ToolCallBlock():
              content.add({
                'type': 'tool_use',
                'id': block.id,
                'name': block.name,
                'input': block.arguments,
              });
            default:
              break; // ThinkingBlocks are not replayed.
          }
        }
        return {'role': 'assistant', 'content': content};
      case ToolResultMessage():
        return {
          'role': 'user',
          'content': [
            {
              'type': 'tool_result',
              'tool_use_id': message.toolCallId,
              'content': message.content,
            },
          ],
        };
      case CustomMessage():
        return {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text':
                  '[custom:${message.messageType}] ${jsonEncode(message.payload)}',
            },
          ],
        };
    }
  }

  Map<String, dynamic> _contentBlock(ContentBlock block) {
    switch (block) {
      case TextBlock():
        return {'type': 'text', 'text': block.text};
      case ImageBlock():
        return {
          'type': 'image',
          'source': {
            'type': 'base64',
            'media_type': block.mimeType,
            'data': block.data,
          },
        };
      case AudioBlock():
        return {
          'type': 'audio',
          'source': {
            'type': 'base64',
            'media_type': block.mimeType,
            'data': block.data,
          },
        };
      case DocumentBlock():
        return {
          'type': 'document',
          'source': {
            'type': 'base64',
            'media_type': block.mimeType,
            'data': block.data,
          },
        };
      default:
        return {'type': 'text', 'text': block.toString()};
    }
  }

  LlmResponse _parseGenerate(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final content = (json['content'] as List?) ?? const [];
    final text = StringBuffer();
    String? thinking;
    final toolCalls = <LlmToolCall>[];
    for (final block in content) {
      final b = block as Map;
      switch (b['type'] as String? ?? '') {
        case 'text':
          text.write(b['text'] as String? ?? '');
        case 'thinking':
          thinking = (b['thinking'] as String?) ?? thinking;
        case 'tool_use':
          toolCalls.add(LlmToolCall(
            id: (b['id'] as String?) ?? '',
            name: (b['name'] as String?) ?? '',
            arguments: _parseArguments(b['input']),
          ));
      }
    }
    final usage = (json['usage'] as Map?) ?? const {};
    return LlmResponse(
      content: text.toString(),
      thinking: thinking,
      toolCalls: toolCalls,
      usage: LlmUsage(
        inputTokens: (usage['input_tokens'] as num?)?.toInt() ?? 0,
        outputTokens: (usage['output_tokens'] as num?)?.toInt() ?? 0,
        cachedTokens:
            (usage['cache_read_input_tokens'] as num?)?.toInt() ?? 0,
      ),
      finishReason:
          _normalizeStopReason(json['stop_reason'] as String?) ?? 'stop',
    );
  }

  /// Tolerates malformed tool arguments (spec 007 AC-2 analogue).
  static Map<String, dynamic> _parseArguments(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        // Malformed JSON — default to an empty map.
      }
    }
    return const {};
  }

  static String? _normalizeStopReason(String? reason) {
    switch (reason) {
      case 'end_turn':
      case 'stop_sequence':
        return 'stop';
      case 'tool_use':
        return 'tool_calls';
      case 'max_tokens':
        return 'length';
      default:
        return reason;
    }
  }
}

/// Buffer accumulating an Anthropic tool_use block's streamed argument JSON.
class _AnthropicToolBuffer {
  final String id;
  final String name;
  String arguments = '';

  _AnthropicToolBuffer({required this.id, required this.name});
}
