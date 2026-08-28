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

    test('LoopSafetyRails inequality detected per-field: outcomeType', () {
      final a = LoopSafetyRails(outcomeType: 'MaxTurnsExceeded', turnNumber: 1, reason: 'r', emittedAt: 1);
      final b = LoopSafetyRails(outcomeType: 'LoopDetected', turnNumber: 1, reason: 'r', emittedAt: 1);
      expect(a == b, isFalse);
    });

    test('LoopSafetyRails inequality detected per-field: turnNumber', () {
      final a = LoopSafetyRails(outcomeType: 'MaxTurnsExceeded', turnNumber: 1, reason: 'r', emittedAt: 1);
      final b = LoopSafetyRails(outcomeType: 'MaxTurnsExceeded', turnNumber: 2, reason: 'r', emittedAt: 1);
      expect(a == b, isFalse);
    });

    test('LoopSafetyRails inequality detected per-field: reason', () {
      final a = LoopSafetyRails(outcomeType: 'MaxTurnsExceeded', turnNumber: 1, reason: 'r1', emittedAt: 1);
      final b = LoopSafetyRails(outcomeType: 'MaxTurnsExceeded', turnNumber: 1, reason: 'r2', emittedAt: 1);
      expect(a == b, isFalse);
    });

    test('LoopSafetyRails inequality detected per-field: emittedAt', () {
      final a = LoopSafetyRails(outcomeType: 'MaxTurnsExceeded', turnNumber: 1, reason: 'r', emittedAt: 1);
      final b = LoopSafetyRails(outcomeType: 'MaxTurnsExceeded', turnNumber: 1, reason: 'r', emittedAt: 2);
      expect(a == b, isFalse);
    });

    test('identical instances are equal via identical() shortcut', () {
      final instance = LoopSafetyRails(outcomeType: 'WallClockTimeout', turnNumber: 5, reason: 'timeout', emittedAt: 5);
      expect(identical(instance, instance), isTrue);
      expect(instance == instance, isTrue);
    });
  });

  group('arrarrny/zuraffa_agent#2 - LoopSafetyRails toString', () {
    test('toString includes outcomeType and turnNumber', () {
      final r = LoopSafetyRails(outcomeType: 'MaxTurnsExceeded', turnNumber: 42, reason: 'limit', emittedAt: 100);
      final s = r.toString();
      expect(s, contains('MaxTurnsExceeded'));
      expect(s, contains('42'));
    });

    test('toString includes reason', () {
      final r = LoopSafetyRails(outcomeType: 'LoopDetected', turnNumber: 1, reason: 'infinite-loop', emittedAt: 1);
      final s = r.toString();
      expect(s, contains('infinite-loop'));
    });

    test('toString omits emittedAt for readability', () {
      final r = LoopSafetyRails(outcomeType: 'WallClockTimeout', turnNumber: 10, reason: 't', emittedAt: 9999);
      final s = r.toString();
      expect(s, isNot(contains('9999')));
    });
  });

  group('arrarrny/zuraffa_agent#2 - LoopSafetyRails clean-arch layers', () {
    test('LoopSafetyRailsProvider is a LoopSafetyRailsService', () {
      final provider = LoopSafetyRailsProvider();
      expect(provider, isA<LoopSafetyRailsService>());
    });

    test('LoopSafetyRailsProvider.current returns the active rails snapshot', () async {
      final rails = await LoopSafetyRailsProvider().current(NoParams());
      expect(rails, isA<LoopSafetyRails>());
      expect(rails.outcomeType, isNotEmpty);
      expect(rails.turnNumber, greaterThanOrEqualTo(0));
      expect(rails.emittedAt, greaterThanOrEqualTo(0));
    });

    test('LoopSafetyRailsProvider.count returns 1', () async {
      expect(await LoopSafetyRailsProvider().count(NoParams()), 1);
    });

    test('LoopSafetyRailsProvider constructor takes no arguments', () {
      expect(() => LoopSafetyRailsProvider(), returnsNormally);
    });
  });
}
