import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;

import 'package:zuraffa_agent/src/engine/events/engine_event.dart';

void main() {
  group('arrarrny/zuraffa_agent#24 — sealed EngineEvent library', () {
    final fixedTime = DateTime.utc(2026, 8, 24, 7, 30, 0);

    test('TurnStarted is an EngineEvent', () {
      final event = TurnStarted(emittedAt: fixedTime);
      expect(event, isA<EngineEvent>());
    });

    test('TurnStarted carries emittedAt + optional turnId', () {
      final event = TurnStarted(emittedAt: fixedTime, turnId: 't-42');
      expect(event.emittedAt, fixedTime);
      expect(event.turnId, 't-42');
    });

    test('TurnStarted.turnId defaults to null for ephemeral turns', () {
      final event = TurnStarted(emittedAt: fixedTime);
      expect(event.turnId, isNull);
    });

    test('switch over EngineEvent is exhaustive when only TurnStarted exists', () {
      // While only TurnStarted exists as a subtype, the switch is exhaustive
      // with just the TurnStarted case. Once #16–#23 land, this test will
      // need to be expanded with one case per subtype (and the `_` arm, if
      // any, removed).
      String describe(EngineEvent e) => switch (e) {
        TurnStarted(:final turnId) => 'turn_started($turnId)',
      };

      final event = TurnStarted(emittedAt: fixedTime, turnId: 't-1');
      expect(describe(event), 'turn_started(t-1)');
    });

    // Sentinel: NoParams is exported by package:zuraffa and reachable.
    // If this stops compiling, the artifact_service.dart from PR #32 broke.
    test('NoParams is reachable (smoke)', () {
      expect(NoParams(), isA<NoParams>());
    });
  });
}
