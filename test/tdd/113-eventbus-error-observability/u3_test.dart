// GENERATED TEST — `zfa tdd gen U3` (spec 044-test-tdd-generation).
//
// behavior_id: U3
// source_criterion: FR-003, EngineEventBus.subscriberErrorEvent
// kind: unit
// description: After the error route runs, the bus MUST publish an
//
// This test asserts the observable behavior described above. It is
// "honest red" on first execution: the paired subject at
// `../../../lib/tdd/113-eventbus-error-observability/u3_subject.dart` is unimplemented, so the test fails through an
// assertion (not an uncaught error, compile/load error, skip, or
// placeholder). Replace the subject's
// stub body with real implementation to make this test pass.
library;

import 'package:test/test.dart';

import 'package:zuraffa_agent/src/engine/engine_event_bus.dart';
import 'package:zuraffa_agent/src/engine/events/engine_event.dart';
import 'package:zuraffa_agent/tdd/113-eventbus-error-observability/u3_subject.dart';

void main() {
  group('U3 (FR-003, EngineEventBus.subscriberErrorEvent)', () {
    test('U3 — After the error route runs, the bus MUST publish an', () {
      final source = TurnStarted(emittedAt: DateTime.now(), turnId: 't-3');
      final error = StateError('observer died');
      // Assertion-shaped guard on the factory.
      expect(() => subject_u3(error, source), returnsNormally);
      final event = subject_u3(error, source);
      expect(event.error, same(error));
      expect(event.eventType, TurnStarted);
      // Through the real bus: a throwing subscriber yields exactly one
      // self-observation event to a wildcard subscriber.
      final bus = EngineEventBus();
      final seen = <EngineEvent>[];
      bus.subscribe<EngineEvent>(seen.add);
      bus.subscribe<TurnStarted>((_) => throw error);
      bus.publish(source);
      final errorEvents = seen.whereType<EngineEventSubscriberError>().toList();
      expect(errorEvents, hasLength(1));
      expect(errorEvents.single.error, same(error));
      // Recursion guard: a failing ERROR-event subscriber does not
      // cascade into another error event.
      bus.subscribe<EngineEventSubscriberError>((_) => throw StateError('error observer broke'));
      final before = seen.length;
      bus.publish(errorEvents.single);
      // Exactly ONE new error event (the published one via the wildcard)
      // — the guard prevented any cascade beyond it.
      final added =
          seen.skip(before).whereType<EngineEventSubscriberError>().length;
      expect(added, 1, reason: 'no self-republication on error events');
    });
  });
}
