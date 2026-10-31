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

/// OpenAI-compatible chat/completions client (spec 007 US1) — works with
/// OpenAI, self-hosted gateways, Kimi, Groq, and any /chat/completions API.
class OpenAiCompatibleClient implements LlmClient {
  @override
  final String providerName;

  /// The transport.
  final LlmTransport transport;

  /// The base URL.
  final String baseUrl;
  @override
  final String model;

  /// The API key.
  final String? apiKey;

  /// The retry config.
  final RetryConfig retryConfig;

  /// The clock.
  final LlmClock clock;

  /// The jitter callback.
  final int Function(int coreDelayMs)? jitter;

  /// Creates an open ai compatible client.
  OpenAiCompatibleClient({
    this.providerName = 'openai',
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
      request: _httpRequest(
        jsonEncode(_buildBody(request, stream: false)),
        request,
      ),
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
      request: _httpRequest(
        jsonEncode(_buildBody(request, stream: true)),
        request,
      ),
      config: retryConfig,
      clock: clock,
      provider: providerName,
      jitter: jitter,
    );

    final toolBuffers = <int, _OpenAiToolBuffer>{};
    var finishReason = 'stop';
    LlmUsage? usage;
    var toolCallsEmitted = false;
    var finalEmitted = false;

    Stream<LlmResponseChunk> finalize() async* {
      if (!toolCallsEmitted && toolBuffers.isNotEmpty) {
        toolCallsEmitted = true;
        yield LlmResponseChunk(
          toolCalls: [
            for (final buffer in toolBuffers.values)
              LlmToolCall(
                id: buffer.id ?? '',
                name: buffer.name,
                arguments: _parseArguments(buffer.arguments),
              ),
          ],
        );
      }
      if (!finalEmitted) {
        finalEmitted = true;
        yield LlmResponseChunk(
          usage: usage,
          isComplete: true,
          finishReason: finishReason,
        );
      }
    }

    await for (final line in response.lines) {
      if (line.isEmpty || line.startsWith(':')) continue;
      if (!line.startsWith('data:')) continue;
      final payload = line.substring(5).trim();
      if (payload == '[DONE]') {
        yield* finalize();
        return;
      }
      final Map<String, dynamic> event;
      try {
        event = jsonDecode(payload) as Map<String, dynamic>;
      } on FormatException {
        continue; // Skip malformed events without killing the stream.
      }

      final choices = (event['choices'] as List?) ?? const [];
      if (choices.isEmpty) {
        final rawUsage = event['usage'];
        if (rawUsage is Map) usage = _parseUsage(rawUsage);
        yield* finalize();
        continue;
      }
      final choice = choices.first as Map;
      final delta = (choice['delta'] as Map?) ?? const {};
      for (final fragment in (delta['tool_calls'] as List?) ?? const []) {
        final f = fragment as Map;
        final index = (f['index'] as num?)?.toInt() ?? 0;
        final buffer = toolBuffers.putIfAbsent(index, _OpenAiToolBuffer.new);
        final id = f['id'] as String?;
        if (id != null && id.isNotEmpty) buffer.id ??= id;
        final function = f['function'] as Map?;
        if (function != null) {
          final name = function['name'] as String?;
          if (name != null && name.isNotEmpty) buffer.name += name;
          buffer.arguments += (function['arguments'] as String?) ?? '';
        }
      }
      final content = delta['content'] as String?;
      if (content != null && content.isNotEmpty) {
        yield LlmResponseChunk(content: content);
      }
      final reason = choice['finish_reason'] as String?;
      if (reason != null) {
        finishReason = reason;
        if (reason == 'tool_calls' && toolBuffers.isNotEmpty) {
          toolCallsEmitted = true;
          yield LlmResponseChunk(
            toolCalls: [
              for (final buffer in toolBuffers.values)
                LlmToolCall(
                  id: buffer.id ?? '',
                  name: buffer.name,
                  arguments: _parseArguments(buffer.arguments),
                ),
            ],
            finishReason: reason,
          );
        }
      }
    }
    // Stream ended without an explicit [DONE] sentinel.
    yield* finalize();
  }

  /// Closes the underlying [transport] — the seam's [LlmClient.close]
  /// contract reaches the socket (issue #159 review: the legacy
  /// LlmHttpTransport closed its HttpClient per call; the default stack is
  /// long-lived for connection reuse, so hosts building clients
  /// transiently close them through this path).
  ///
  /// Ownership: closing this client closes [transport]. When the transport
  /// was injected and is shared with other clients, closing THIS client
  /// closes it for all of them.
  @override
  Future<void> close() async => transport.close();

  LlmHttpRequest _httpRequest(String body, LlmRequest request) =>
      LlmHttpRequest(
        uri: Uri.parse(
          '$baseUrl${baseUrl.endsWith('/') ? '' : '/'}chat/completions',
        ),
        headers: {
          if (apiKey != null) 'authorization': 'Bearer $apiKey',
          'content-type': 'application/json',
          // Caller-supplied headers win — traceparent and friends.
          ...request.headers,
        },
        body: body,
      );

  Map<String, dynamic> _buildBody(LlmRequest request, {required bool stream}) =>
      {
        'model': model,
        'messages': [
          if (request.systemPrompt != null)
            {'role': 'system', 'content': request.systemPrompt},
          ...request.messages.map(_messageToJson),
        ],
        if (request.tools != null)
          'tools': [
            for (final tool in request.tools!)
              {
                'type': 'function',
                'function': {
                  'name': tool.name,
                  'description': tool.description,
                  'parameters': tool.parameters,
                },
              },
          ],
        if (request.temperature != null) 'temperature': request.temperature,
        if (request.maxTokens != null) 'max_tokens': request.maxTokens,
        if (request.toolChoice != null) 'tool_choice': request.toolChoice,
        if (request.parallelToolCalls != null)
          'parallel_tool_calls': request.parallelToolCalls,
        if (request.responseFormat != null)
          'response_format': request.responseFormat,
        if (stream) 'stream': true,
        if (stream) 'stream_options': {'include_usage': true},
      };

  Map<String, dynamic> _messageToJson(AgentMessage message) {
    switch (message) {
      case UserMessage():
        return {
          'role': 'user',
          'content': [for (final block in message.content) _contentPart(block)],
        };
      case AssistantMessage():
        final textParts = <Map<String, dynamic>>[];
        final toolCalls = <Map<String, dynamic>>[];
        for (final block in message.content) {
          switch (block) {
            case TextBlock():
              textParts.add({'type': 'text', 'text': block.text});
            case ToolCallBlock():
              toolCalls.add({
                'id': block.id,
                'type': 'function',
                'function': {
                  'name': block.name,
                  'arguments': jsonEncode(block.arguments),
                },
              });
            default:
              break; // ThinkingBlocks are not replayed to OpenAI.
          }
        }
        return {
          'role': 'assistant',
          if (textParts.length == 1)
            'content': textParts.single['text']
          else if (textParts.isNotEmpty)
            'content': textParts,
          if (toolCalls.isNotEmpty) 'tool_calls': toolCalls,
        };
      case ToolResultMessage():
        return {
          'role': 'tool',
          'tool_call_id': message.toolCallId,
          'content': message.content,
        };
      case CustomMessage():
        return {
          'role': 'user',
          'content':
              '[custom:${message.messageType}] ${jsonEncode(message.payload)}',
        };
    }
  }

  Map<String, dynamic> _contentPart(ContentBlock block) {
    switch (block) {
      case TextBlock():
        return {'type': 'text', 'text': block.text};
      case ImageBlock():
        final url = block.data.startsWith('http')
            ? block.data
            : 'data:${block.mimeType};base64,${block.data}';
        return {
          'type': 'image_url',
          'image_url': {'url': url},
        };
      case AudioBlock():
        return {
          'type': 'input_audio',
          'input_audio': {
            'data': block.data,
            'format': block.mimeType.replaceAll('audio/', ''),
          },
        };
      case DocumentBlock():
        return {
          'type': 'file',
          'file': {
            'filename': block.title ?? 'document',
            'file_data': 'data:${block.mimeType};base64,${block.data}',
          },
        };
      default:
        return {'type': 'text', 'text': block.toString()};
    }
  }

  LlmResponse _parseGenerate(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final choices = json['choices'] as List? ?? const [];
    final choice = choices.isEmpty ? <String, dynamic>{} : choices.first as Map;
    final message = (choice['message'] as Map?)?.cast<String, dynamic>() ?? {};
    return LlmResponse(
      content: (message['content'] as String?) ?? '',
      thinking: _reasoningOf(message),
      toolCalls: [
        for (final tc in (message['tool_calls'] as List?) ?? const [])
          LlmToolCall(
            id: (tc as Map)['id'] as String? ?? '',
            name: ((tc['function'] as Map)['name'] as String?) ?? '',
            arguments: _parseArguments((tc['function'] as Map)['arguments']),
          ),
      ],
      usage: _parseUsage(json['usage']),
      finishReason: (choice['finish_reason'] as String?) ?? 'stop',
    );
  }

  /// Surfaces gateway reasoning as [LlmResponse.thinking] — the `reasoning`
  /// string (Kimi/OpenRouter-style) or the `reasoning_details` list,
  /// reassembled in order. The legacy LlmHttpTransport parser exposed the
  /// same fields as ChatCompletion.reasoning, which the engine persists as
  /// assistant thinking (spec 002 FR-002); routing LlmClientProvider through
  /// this client (issue #124) must not drop it.
  static String? _reasoningOf(Map<String, dynamic> message) {
    final reasoning = message['reasoning'] as String?;
    if (reasoning != null && reasoning.isNotEmpty) return reasoning;
    final details = message['reasoning_details'];
    if (details is List) {
      final joined = details
          .whereType<Map<String, dynamic>>()
          .map((d) => d['text'] as String? ?? '')
          .where((t) => t.isNotEmpty)
          .join('\n');
      if (joined.isNotEmpty) return joined;
    }
    return null;
  }

  static LlmUsage _parseUsage(dynamic usage) {
    if (usage is! Map) return const LlmUsage();
    return LlmUsage(
      inputTokens: (usage['prompt_tokens'] as num?)?.toInt() ?? 0,
      outputTokens: (usage['completion_tokens'] as num?)?.toInt() ?? 0,
      cachedTokens:
          ((usage['prompt_tokens_details'] as Map?)?['cached_tokens'] as num?)
              ?.toInt() ??
          0,
      thoughtTokens:
          ((usage['completion_tokens_details'] as Map?)?['reasoning_tokens']
                  as num?)
              ?.toInt() ??
          0,
    );
  }

  /// Tolerates malformed tool arguments (spec 007 AC-2): any unparsable
  /// argument payload defaults to an empty map.
  static Map<String, dynamic> _parseArguments(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        // Malformed JSON from the model — default to an empty map.
      }
    }
    return const {};
  }
}

/// Buffer accumulating streamed tool-call fragments for one index slot.
class _OpenAiToolBuffer {
  String? id;
  String name = '';
  String arguments = '';
}
