// Test helper: fixture-replaying LlmTransport (spec 007).

import 'dart:async';

import 'package:zuraffa_agent/src/llm/llm_client.dart';
import 'package:zuraffa_agent/src/llm/llm_transport.dart';

/// One scripted transport outcome.
class ScriptedResponse {
  final int statusCode;
  final Map<String, String> headers;

  /// Body for [FakeLlmTransport.send] calls.
  final String? body;

  /// Line stream for [FakeLlmTransport.openStream] calls.
  final List<String>? lines;

  /// When set, the call throws [LlmNetworkException] with this cause.
  final Object? networkError;

  const ScriptedResponse({
    this.statusCode = 200,
    this.headers = const {},
    this.body,
    this.lines,
    this.networkError,
  });
}

/// A fake [LlmTransport] that records requests and replays scripted responses.
class FakeLlmTransport implements LlmTransport {
  final List<LlmHttpRequest> requests = [];
  final List<ScriptedResponse> _script;
  final String provider;
  int _cursor = 0;

  FakeLlmTransport({
    required List<ScriptedResponse> script,
    this.provider = 'fake',
  }) : _script = script;

  ScriptedResponse _next(String method) {
    if (_cursor >= _script.length) {
      throw StateError(
          'FakeLlmTransport($provider): no scripted response left for $method '
          '(scripted ${_script.length} responses, got call #${_cursor + 1})');
    }
    return _script[_cursor++];
  }

  @override
  Future<LlmHttpResponse> send(LlmHttpRequest request) async {
    requests.add(request);
    final scripted = _next('send');
    if (scripted.networkError != null) {
      throw LlmNetworkException(
          provider: provider, cause: scripted.networkError!);
    }
    return LlmHttpResponse(
      statusCode: scripted.statusCode,
      headers: scripted.headers,
      body: scripted.body ?? '',
    );
  }

  @override
  Future<LlmStreamResponse> openStream(LlmHttpRequest request) async {
    requests.add(request);
    final scripted = _next('openStream');
    if (scripted.networkError != null) {
      throw LlmNetworkException(
          provider: provider, cause: scripted.networkError!);
    }
    return LlmStreamResponse(
      statusCode: scripted.statusCode,
      headers: scripted.headers,
      lines: Stream.fromIterable(scripted.lines ?? const <String>[]),
    );
  }
}
