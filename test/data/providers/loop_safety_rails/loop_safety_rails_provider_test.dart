// HAND-CURATED regression tests for the LoopSafetyRails value object +
// LoopSafetyRailsProvider stub. Pattern mirrors spec 033.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/domain/entities/loop_safety_rails/loop_safety_rails.dart';
import 'package:zuraffa_agent/src/domain/services/loop_safety_rails_service.dart';
import 'package:zuraffa_agent/src/data/providers/loop_safety_rails/loop_safety_rails_provider.dart';

void main() {
  group('arrarrny/zuraffa_agent#2 - LoopSafetyRails value equality', () {
    test('LoopSafetyRails equality is value-based across all fields', () {
      final a = LoopSafetyRails(outcomeType: 'MaxTurnsExceeded', turnNumber: 10, reason: 'val-a', emittedAt: 10);
      final b = LoopSafetyRails(outcomeType: 'MaxTurnsExceeded', turnNumber: 10, reason: 'val-a', emittedAt: 10);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('LoopSafetyRails inequality differs when a field changes', () {
      final a = LoopSafetyRails(outcomeType: 'MaxTurnsExceeded', turnNumber: 10, reason: 'val-a', emittedAt: 10);
      final b = LoopSafetyRails(outcomeType: 'LoopDetected', turnNumber: 20, reason: 'val-b', emittedAt: 20);
      expect(a == b, isFalse);
    });
  });

  group('arrarrny/zuraffa_agent#2 - LoopSafetyRails clean-arch layers', () {
    test('LoopSafetyRailsProvider is a LoopSafetyRailsService', () {
      final provider = LoopSafetyRailsProvider();
      expect(provider, isA<LoopSafetyRailsService>());
    });

    test('LoopSafetyRailsProvider.current throws UnimplementedError on NoParams', () {
      final provider = LoopSafetyRailsProvider();
      expect(
        () => provider.current(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('LoopSafetyRailsProvider.count throws UnimplementedError on NoParams', () {
      final provider = LoopSafetyRailsProvider();
      expect(
        () => provider.count(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
