// Ported from dart_agent_core (MIT License, Copyright (c) 2024-2026
// contributors) — see NOTICE. dart_agent_core is NOT a dependency of this
// package (spec 007 FR-007, constitution VIII): the behavior is re-implemented
// in-tree per specs/007-llm-provider-clients/spec.md with this attribution
// retained.

import 'dart:async';
import 'dart:convert';

import '../types.dart';
import 'llm_client.dart';
import 'llm_clock.dart';
import 'llm_transport.dart';
import 'retry.dart';
import 'sse_chat_chunk_parser.dart';

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
  Stream<LlmResponseChunk> stream(LlmRequest request) {
    // StreamController forwarding instead of `async*` (issue #163): an
    // `async*` frame suspended at `await for`/`yield*` never resumes on
    // cancel (Dart 3.13.5), so the consumer's `subscription.cancel()` hung.
    // Cancel here becomes a direct subscription cancel down to the parser,
    // which completes; pause/resume forward so the transport's TCP
    // backpressure contract is kept.
    late StreamController<LlmResponseChunk> controller;
    StreamSubscription<LlmResponseChunk>? inner;
    var cancelled = false;
    var paused = false;

    Future<void> start() async {
      try {
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
        if (cancelled) {
          // Cancelled while the request was in flight: still detach from
          // the response we just opened (nothing can be delivered now).
          await parseOpenAiSseChunkStream(response.lines).listen(null).cancel();
          return;
        }

        // One shared SSE parser for both OpenAI-compatible streaming paths
        // (issue #123 review): reasoning deltas surface as thinking chunks
        // here exactly as on the legacy LlmHttpTransport path. Assigned
        // straight to `inner` so the outer cancel (onCancel) detaches this
        // exact subscription (issue #163).
        inner = parseOpenAiSseChunkStream(response.lines).listen(
          (chunk) {
            if (!cancelled) controller.add(chunk);
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!cancelled) controller.addError(error, stackTrace);
          },
          onDone: () {
            if (!cancelled) controller.close();
          },
        );
        if (paused) inner!.pause();
      } catch (error, stackTrace) {
        if (!cancelled) {
          controller.addError(error, stackTrace);
          unawaited(controller.close());
        }
      }
    }

    controller = StreamController<LlmResponseChunk>(
      onListen: start,
      onPause: () {
        paused = true;
        inner?.pause();
      },
      onResume: () {
        paused = false;
        inner?.resume();
      },
      onCancel: () async {
        cancelled = true;
        final cancel = inner?.cancel();
        inner = null;
        await cancel;
      },
    );
    return controller.stream;
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
