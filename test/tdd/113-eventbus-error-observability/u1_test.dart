// GENERATED TEST — `zfa tdd gen U1` (spec 044-test-tdd-generation).
//
// behavior_id: U1
// source_criterion: FR-001, EngineEventBus.logSubscriberError
// kind: unit
// description: With no consumer hook installed, the bus MUST route
//
// This test asserts the observable behavior described above. It is
// "honest red" on first execution: the paired subject at
// `package:zuraffa_agent/tdd/113-eventbus-error-observability/u1_subject.dart` is unimplemented, so the test fails through an
// assertion (not an uncaught error, compile/load error, skip, or
// placeholder). Replace the subject's
// stub body with real implementation to make this test pass.
library;

import 'package:test/test.dart';
import 'package:logging/logging.dart';

import 'package:zuraffa_agent/src/engine/engine_event_bus.dart';
import 'package:zuraffa_agent/src/engine/events/engine_event.dart';
import 'package:zuraffa_agent/src/logging/agent_log.dart';
import 'package:zuraffa_agent/src/logging/memory_log_sink.dart';
import 'package:zuraffa_agent/tdd/113-eventbus-error-observability/u1_subject.dart';

void main() {
  group('U1 (FR-001, EngineEventBus.logSubscriberError)', () {
    test('U1 — With no consumer hook installed, the bus MUST route', () {
      ZuraffaLogging.reset();
      addTearDown(ZuraffaLogging.reset);
      final sink = MemoryLogSink();
      ZuraffaLogging.install(level: Level.ALL, onRecord: sink.add);
      final source = TurnStarted(emittedAt: DateTime.now(), turnId: 't-1');
      // Assertion-shaped guard: an unimplemented route fails HERE.
      expect(() => subject_u1(StateError('observer broke'), source),
          returnsNormally);
      final record = sink.firstWhereMessage('subscriber error on TurnStarted');
      expect(record, isNotNull);
      expect(record!.level, Level.SEVERE);
      expect(record.loggerName, 'zuraffa.agent.eventBus');
      expect(record.message, contains('observer broke'));
    });
  });
}
