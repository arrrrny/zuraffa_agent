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

import 'dart:convert';
import 'dart:io';

import '../../../domain/entities/llm_client/chat_completion.dart';
import '../../../domain/entities/llm_client/chat_message.dart';

/// Raised when a completion request fails at the transport layer.
class LlmTransportException implements Exception {
  final int? statusCode;
  final String body;
  final String message;

  LlmTransportException({this.statusCode, required this.body, required this.message});

  @override
  String toString() =>
      'LlmTransportException(${statusCode ?? 'network'}: $message)${body.isNotEmpty ? '\n$body' : ''}';
}

/// Builds an OpenAI-compatible chat-completion request body.
///
/// Pure function — no I/O, fully unit-testable.
Map<String, dynamic> buildChatCompletionRequest({
  required String model,
  required List<ChatMessage> messages,
  bool stream = false,
}) {
  return {
    'model': model,
    'messages': messages.map((m) => m.toJson()).toList(growable: false),
    'stream': stream,
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
  final message = choice['message'] as Map<String, dynamic>? ?? <String, dynamic>{};
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
      request.write(jsonEncode(buildChatCompletionRequest(
        model: model,
        messages: messages,
        stream: stream,
      )));
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
}
