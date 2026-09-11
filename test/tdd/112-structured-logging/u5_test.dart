// GENERATED TEST — `zfa tdd gen U5` (spec 044-test-tdd-generation).
//
// behavior_id: U5
// source_criterion: FR-005, AgentLog.retryWarning
// kind: unit
// description: The first adoption sites MUST ship with this spec: the LLM
//
// This test asserts the observable behavior described above. It is
// "honest red" on first execution: the paired subject at
// `package:zuraffa_agent/tdd/112-structured-logging/u5_subject.dart` is unimplemented, so the test fails through an
// assertion (not an uncaught error, compile/load error, skip, or
// placeholder). Replace the subject's
// stub body with real implementation to make this test pass.
library;

import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'package:zuraffa_agent/src/llm/llm_clock.dart';
import 'package:zuraffa_agent/src/llm/llm_client.dart';
import 'package:zuraffa_agent/src/llm/llm_transport.dart';
import 'package:zuraffa_agent/src/llm/retry.dart';
import 'package:zuraffa_agent/src/logging/agent_log.dart';
import 'package:zuraffa_agent/src/logging/memory_log_sink.dart';
import 'package:zuraffa_agent/tdd/112-structured-logging/u5_subject.dart';
import 'package:zuraffa_agent/tdd/112-structured-logging/u5_subject.dart' as subject;

class _ScriptedTransport implements LlmTransport {
  int calls = 0;
  @override
  Future<LlmHttpResponse> send(LlmHttpRequest request) async {
    calls++;
    if (calls == 1) {
      throw const LlmNetworkException(provider: 'scripted', cause: 'boom');
    }
    return const LlmHttpResponse(statusCode: 200);
  }

  @override
  Future<LlmStreamResponse> openStream(LlmHttpRequest request) async =>
      LlmStreamResponse(statusCode: 200, lines: Stream<String>.empty());
}

class _InstantClock implements LlmClock {
  @override
  DateTime now() => DateTime.fromMillisecondsSinceEpoch(0);
  @override
  Future<void> sleep(int milliseconds) async {}
}

void main() {
  group('U5 (FR-005, AgentLog.retryWarning)', () {
    test('U5 — The first adoption sites MUST ship with this spec: the LLM', () async {
      ZuraffaLogging.reset();
      addTearDown(ZuraffaLogging.reset);
      // Assertion-shaped guard on the contract surface itself.
      expect(
        () => subject_u5(1, const Duration(milliseconds: 500),
            const LlmNetworkException(provider: 'scripted', cause: 'boom')),
        returnsNormally,
      );
      // Real adoption site: a transport that fails once then succeeds
      // must produce exactly one WARNING record on the llm logger
      // carrying attempt, delay, and the error.
      final sink = MemoryLogSink();
      ZuraffaLogging.install(level: Level.WARNING, onRecord: sink.add);
      final transport = _ScriptedTransport();
      await sendWithRetry(
        transport: transport,
        request: LlmHttpRequest(uri: Uri.parse('https://x.test/v1')),
        config: const RetryConfig(maxAttempts: 3, baseDelayMs: 250),
        clock: _InstantClock(),
        provider: 'scripted',
      );
      expect(transport.calls, 2);
      final warning = sink.firstWhereMessage('retry scheduled');
      expect(warning, isNotNull);
      expect(warning!.level, Level.WARNING);
      expect(warning.loggerName, 'zuraffa.agent.llm');
      expect(warning.message, contains('attempt=1'));
      expect(warning.message, contains('delay=250ms'));
      expect(warning.message, contains('boom'));
    });
  });
}
