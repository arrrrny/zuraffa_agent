// GENERATED TEST — `zfa tdd gen U4` (spec 044-test-tdd-generation).
//
// behavior_id: U4
// source_criterion: FR-004, EngineEventBus.logSubscriberError
// kind: unit
// description: A throwing hook or a throwing subscriber of the
//
// This test asserts the observable behavior described above. It is
// "honest red" on first execution: the paired subject at
// `package:zuraffa_agent/tdd/113-eventbus-error-observability/u4_subject.dart` is unimplemented, so the test fails through an
// assertion (not an uncaught error, compile/load error, skip, or
// placeholder). Replace the subject's
// stub body with real implementation to make this test pass.
library;

import 'package:test/test.dart';
import 'package:logging/logging.dart';

import 'package:zuraffa_agent/src/engine/events/engine_event.dart';
import 'package:zuraffa_agent/src/logging/agent_log.dart';
import 'package:zuraffa_agent/src/logging/memory_log_sink.dart';
import 'package:zuraffa_agent/tdd/113-eventbus-error-observability/u4_subject.dart';

void main() {
  group('U4 (FR-004, EngineEventBus.logSubscriberError)', () {
    test('U4 — A throwing hook or a throwing subscriber of the', () {
      ZuraffaLogging.reset();
      addTearDown(ZuraffaLogging.reset);
      final sink = MemoryLogSink();
      ZuraffaLogging.install(level: Level.ALL, onRecord: sink.add);
      final source = TurnStarted(emittedAt: DateTime.now(), turnId: 't-4');
      // Assertion-shaped guard: publish never throws even though BOTH
      // the subscriber and the hook throw.
      expect(() => subject_u4(StateError('sub broke'), source),
          returnsNormally);
      // The hook failure itself is logged, not swallowed.
      expect(sink.firstWhereMessage('hook failed'), isNotNull);
    });
  });
}
