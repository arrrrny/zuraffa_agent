// Test helper: outcome-scripting LlmClient (spec 008) — mirrors
// FakeLlmTransport's script pattern for the LlmClient interface level.

import 'package:zuraffa_agent/src/llm/llm_client.dart';

/// One scripted outcome for a generate() or stream() call.
class ScriptedOutcome {
  final LlmResponse? response;
  final Object? error;
  final List<LlmResponseChunk>? chunks;

  /// Error thrown AFTER [chunks] were already emitted (mid-stream failure).
  final Object? streamError;

  const ScriptedOutcome({this.response, this.error, this.chunks, this.streamError});
}

class FakeLlmClient implements LlmClient {
  @override
  final String providerName;
  @override
  final String model;
  final List<ScriptedOutcome> outcomes;
  int generateCalls = 0;
  int streamCalls = 0;
  final List<LlmRequest> requests = [];
  int _cursor = 0;

  FakeLlmClient({
    required this.providerName,
    this.model = 'test-model',
    required this.outcomes,
  });

  ScriptedOutcome _next() {
    if (_cursor >= outcomes.length) {
      throw StateError(
          'FakeLlmClient($providerName): no scripted outcome left '
          '(scripted ${outcomes.length}, got call #${_cursor + 1})');
    }
    return outcomes[_cursor++];
  }

  @override
  Future<LlmResponse> generate(LlmRequest request) async {
    generateCalls += 1;
    requests.add(request);
    final outcome = _next();
    if (outcome.error != null) throw outcome.error!;
    return outcome.response ?? const LlmResponse(content: '');
  }

  @override
  Stream<LlmResponseChunk> stream(LlmRequest request) async* {
    streamCalls += 1;
    final outcome = _next();
    for (final chunk in outcome.chunks ?? const <LlmResponseChunk>[]) {
      yield chunk;
    }
    if (outcome.streamError != null) throw outcome.streamError!;
  }

  @override
  Future<void> close() async {}
}
