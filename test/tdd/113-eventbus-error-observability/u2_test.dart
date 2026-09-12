// GENERATED TEST — `zfa tdd gen U2` (spec 044-test-tdd-generation).
//
// behavior_id: U2
// source_criterion: FR-002, EngineEventBus.logSubscriberError
// kind: unit
// description: A consumer-provided `onSubscriberError` hook MUST fully
//
// This test asserts the observable behavior described above. It is
// "honest red" on first execution: the paired subject at
// `package:zuraffa_agent/tdd/113-eventbus-error-observability/u2_subject.dart` is unimplemented, so the test fails through an
// assertion (not an uncaught error, compile/load error, skip, or
// placeholder). Replace the subject's
// stub body with real implementation to make this test pass.
library;

import 'package:test/test.dart';
import 'package:logging/logging.dart';

import 'package:zuraffa_agent/src/engine/events/engine_event.dart';
import 'package:zuraffa_agent/src/logging/agent_log.dart';
import 'package:zuraffa_agent/src/logging/memory_log_sink.dart';
import 'package:zuraffa_agent/tdd/113-eventbus-error-observability/u2_subject.dart';

void main() {
  group('U2 (FR-002, EngineEventBus.logSubscriberError)', () {
    test('U2 — A consumer-provided `onSubscriberError` hook MUST fully', () {
      ZuraffaLogging.reset();
      addTearDown(ZuraffaLogging.reset);
      u2HookCalls.clear();
      final sink = MemoryLogSink();
      ZuraffaLogging.install(level: Level.ALL, onRecord: sink.add);
      final error = StateError('custom hook handles this');
      final source = TurnStarted(emittedAt: DateTime.now(), turnId: 't-2');
      // Assertion-shaped guard.
      expect(() => subject_u2(error, source), returnsNormally);
      // The custom hook captured the failure...
      expect(u2HookCalls, hasLength(1));
      expect(u2HookCalls.single.$1, same(error));
      expect(u2HookCalls.single.$2, same(source));
      // ...and the default SEVERE route stayed silent.
      expect(sink.firstWhereMessage('subscriber error'), isNull);
    });
  });
}
