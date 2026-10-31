// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#5 (R4 - providers & fallback).
//
// LlmHttpTransport - the platform-I/O boundary for the LlmClient. This is the
// ONLY file in lib/src that imports dart:io; it is listed in the engine
// runtime purity allowlist (.github/workflows/pipeline.yml, Constitution VII)
// with justification: a real LLM call on the Dart VM requires an HTTP client,
// and proxy egress (HTTP CONNECT) requires dart:io's HttpClient.findProxy.
// The pure request-build / response-parse helpers below are covered by unit
// tests without any network; the network path is covered by the live
// integration test (test/integration/llm_client_proxy_test.dart).

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../domain/entities/llm_client/chat_completion.dart';
import '../../../domain/entities/llm_client/chat_message.dart';
import '../../../llm/llm_client.dart';
import '../../../llm/sse_chat_chunk_parser.dart';

/// Raised when a completion request fails at the transport layer.
class LlmTransportException implements Exception {
  /// The status code.
  final int? statusCode;

  /// The body.
  final String body;

  /// The message.
  final String message;

  /// Creates an LLM transport exception.
  LlmTransportException({
    this.statusCode,
    required this.body,
    required this.message,
  });

  @override
  String toString() =>
      'LlmTransportException(${statusCode ?? 'network'}: $message)'
      '${body.isNotEmpty ? '\n$body' : ''}';
}

/// Builds an OpenAI-compatible chat-completion request body.
///
/// Pure function — no I/O, fully unit-testable. A streamed request opts into
/// usage reporting (`stream_options.include_usage`), mirroring
/// `OpenAiCompatibleClient._buildBody`: spec-compliant gateways emit the
/// trailing usage event only when the client asks for it, and without the
/// opt-in every streaming turn silently reports zero token usage.
Map<String, dynamic> buildChatCompletionRequest({
  required String model,
  required List<ChatMessage> messages,
  bool stream = false,
}) {
  return {
    'model': model,
    'messages': messages.map((m) => m.toJson()).toList(growable: false),
    'stream': stream,
    if (stream) 'stream_options': {'include_usage': true},
  };
}

/// Parses an OpenAI-compatible chat.completion JSON response.
///
/// Pure function — no I/O, fully unit-testable. Throws
/// [LlmTransportException] when the payload is missing the expected shape.
ChatCompletion parseChatCompletionResponse(Map<String, dynamic> json) {
  final choices = json['choices'];
  if (choices is! List || choices.isEmpty) {
    throw LlmTransportException(
      body: jsonEncode(json),
      message: 'response contained no choices',
    );
  }
  final choice = choices[0] as Map<String, dynamic>;
  final message =
      choice['message'] as Map<String, dynamic>? ?? <String, dynamic>{};
  final content = (message['content'] as String?) ?? '';
  if (content.isEmpty) {
    throw LlmTransportException(
      body: jsonEncode(json),
      message: 'response message content was empty',
    );
  }

  String? reasoning = message['reasoning'] as String?;
  if (reasoning == null) {
    final details = message['reasoning_details'];
    if (details is List) {
      reasoning = details
          .whereType<Map<String, dynamic>>()
          .map((d) => d['text'] as String? ?? '')
          .where((t) => t.isNotEmpty)
          .join('\n');
      if (reasoning.isEmpty) reasoning = null;
    }
  }

  final finishReason = (choice['finish_reason'] as String?) ?? 'stop';
  final usage = TokenUsage.fromJson(json);

  return ChatCompletion(
    content: content,
    reasoning: reasoning,
    finishReason: finishReason,
    usage: usage,
  );
}

/// Strips a `scheme://` prefix so the value can be used in an HttpClient
/// `findProxy` directive (e.g. `http://localhost:8890` -> `localhost:8890`).
String _stripScheme(String url) {
  final idx = url.indexOf('://');
  return idx < 0 ? url : url.substring(idx + 3);
}

/// HTTP transport that performs chat-completion calls against an
/// OpenAI-compatible gateway, optionally routing through a local proxy.
class LlmHttpTransport {
  /// Factory for the underlying [HttpClient]; injectable for tests.
  final HttpClient Function() clientFactory;

  /// Creates an LLM HTTP transport.
  LlmHttpTransport({HttpClient Function()? clientFactory})
    : clientFactory = clientFactory ?? (() => HttpClient());

  /// Sends a chat-completion request and returns the parsed completion.
  ///
  /// When [proxyUrl] is set, all traffic is routed through it via an HTTP
  /// CONNECT tunnel. The API key is sent only in the Authorization header and
  /// is never logged.
  Future<ChatCompletion> complete({
    required String baseUrl,
    required String apiKey,
    String? proxyUrl,
    required String model,
    required List<ChatMessage> messages,
    bool stream = false,
    Duration? timeout,
  }) async {
    final client = clientFactory();
    if (timeout != null) {
      client.connectionTimeout = timeout;
    }
    if (proxyUrl != null && proxyUrl.isNotEmpty) {
      final hostPort = _stripScheme(proxyUrl);
      client.findProxy = (uri) => 'PROXY $hostPort';
    }
    try {
      final uri = Uri.parse('$baseUrl/chat/completions');
      final request = await client.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Authorization', 'Bearer $apiKey');
      request.write(
        jsonEncode(
          buildChatCompletionRequest(
            model: model,
            messages: messages,
            stream: stream,
          ),
        ),
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) {
        throw LlmTransportException(
          statusCode: response.statusCode,
          body: body,
          message: 'gateway returned ${response.statusCode}',
        );
      }
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw LlmTransportException(
          body: body,
          message: 'response was not a JSON object',
        );
      }
      return parseChatCompletionResponse(decoded);
    } finally {
      client.close(force: true);
    }
  }

  /// Streams a chat completion and emits `LlmResponseChunk`s incrementally
  /// as the gateway emits SSE deltas (issue #123).
  ///
  /// The request is the same OpenAI-compatible `/chat/completions` call as
  /// [complete] with `stream: true`. Chunks follow the provider clients'
  /// streaming shapes: `delta.content` -> content chunks, `delta.reasoning`
  /// / `delta.reasoning_content` -> thinking chunks, `delta.tool_calls`
  /// fragments buffered and emitted once `finish_reason` arrives, and the
  /// trailing usage event folded into the final `isComplete: true` chunk.
  ///
  /// Backpressure: the returned stream forwards `pause`/`resume` to the
  /// inner subscriptions — pausing the consumer pauses the socket read. The
  /// engine loop wraps it in a bounded buffer (see
  /// `engine_loop_executor.dart`), which is where the watermark contract
  /// lives.
  ///
  /// Unlike [complete], no retry policy is applied: a connection cannot be
  /// replayed after partial chunks were already delivered downstream.
  /// Errors (non-2xx status, connection failure) surface on the stream's
  /// error channel; the HTTP client is closed on completion, error, and
  /// cancellation alike.
  ///
  /// Delivery is `StreamController` forwarding, not `async*` (issue #163):
  /// `onCancel` cancels the inner subscription directly (a cancel that
  /// always completes — an `async*` frame suspended at `await for` never
  /// resumed, so `subscription.cancel()` hung) and eagerly force-closes the
  /// [HttpClient], so mid-stream teardown can no longer be skipped.
  Stream<LlmResponseChunk> streamComplete({
    required String baseUrl,
    required String apiKey,
    String? proxyUrl,
    required String model,
    required List<ChatMessage> messages,
    Duration? timeout,
  }) {
    late StreamController<LlmResponseChunk> controller;
    HttpClient? client;
    StreamSubscription<LlmResponseChunk>? inner;
    var tornDown = false;
    var cancelled = false;
    var paused = false;

    void teardown() {
      if (tornDown) return;
      tornDown = true;
      client?.close(force: true);
    }

    Future<void> start() async {
      final HttpClient httpClient;
      try {
        httpClient = clientFactory();
        client = httpClient;
        if (timeout != null) {
          httpClient.connectionTimeout = timeout;
        }
        if (proxyUrl != null && proxyUrl.isNotEmpty) {
          final hostPort = _stripScheme(proxyUrl);
          httpClient.findProxy = (uri) => 'PROXY $hostPort';
        }
        final Uri uri = Uri.parse('$baseUrl/chat/completions');
        final request = await httpClient.postUrl(uri);
        request.headers.set('Content-Type', 'application/json');
        request.headers.set('Authorization', 'Bearer $apiKey');
        request.write(
          jsonEncode(
            buildChatCompletionRequest(
              model: model,
              messages: messages,
              stream: true,
            ),
          ),
        );
        final response = await request.close();
        if (cancelled) {
          teardown();
          return;
        }
        if (response.statusCode != 200) {
          final body = await response.transform(utf8.decoder).join();
          teardown();
          if (!cancelled) {
            controller.addError(
              LlmTransportException(
                statusCode: response.statusCode,
                body: body,
                message: 'gateway returned ${response.statusCode}',
              ),
              StackTrace.current,
            );
            unawaited(controller.close());
          }
          return;
        }
        if (cancelled) {
          teardown();
          return;
        }
        // Assigned straight to `inner` so the outer cancel (onCancel)
        // detaches this exact subscription (issue #163).
        inner =
            parseChatCompletionChunkStream(
              response.transform(utf8.decoder).transform(const LineSplitter()),
            ).listen(
              (chunk) {
                if (!cancelled) controller.add(chunk);
              },
              onError: (Object error, StackTrace stackTrace) {
                if (!cancelled) controller.addError(error, stackTrace);
              },
              onDone: () {
                if (!cancelled) {
                  teardown();
                  controller.close();
                }
              },
            );
        if (paused) inner!.pause();
      } catch (error, stackTrace) {
        teardown();
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
        teardown(); // Eager — issue #163: teardown must not depend on a
        // generator `finally` that never runs.
        await cancel;
      },
    );
    return controller.stream;
  }
}

/// Parses an OpenAI-compatible streaming (SSE) response body into
/// `LlmResponseChunk`s (issue #123).
///
/// Pure function — no I/O, fully unit-testable. Delegate to the shared
/// parser (`parseOpenAiSseChunkStream` in
/// lib/src/llm/sse_chat_chunk_parser.dart) so both OpenAI-compatible
/// streaming paths — this transport and `OpenAiCompatibleClient.stream` —
/// run one wire implementation instead of twin state machines (issue #123
/// review).
Stream<LlmResponseChunk> parseChatCompletionChunkStream(Stream<String> lines) =>
    parseOpenAiSseChunkStream(lines);
