// HAND-CURATED regression tests for the DartIoFreeGate value object +
// DartIoFreeGateProvider stub. Pattern mirrors spec 033.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/domain/entities/dart_io_free_gate/dart_io_free_gate.dart';
import 'package:zuraffa_agent/src/domain/services/dart_io_free_gate_service.dart';
import 'package:zuraffa_agent/src/data/providers/dart_io_free_gate/dart_io_free_gate_provider.dart';

void main() {
  group('arrarrny/zuraffa_agent#7 - DartIoFreeGate value equality', () {
    test('DartIoFreeGate equality is value-based across all fields', () {
      final a = DartIoFreeGate(id: 'id-a', gateName: 'dart_io_free', enforcedPaths: const ['a','b'], violationCount: 10);
      final b = DartIoFreeGate(id: 'id-a', gateName: 'dart_io_free', enforcedPaths: const ['a','b'], violationCount: 10);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('DartIoFreeGate inequality differs when a field changes', () {
      final a = DartIoFreeGate(id: 'id-a', gateName: 'dart_io_free', enforcedPaths: const ['a','b'], violationCount: 10);
      final b = DartIoFreeGate(id: 'id-b', gateName: 'dart_io_free', enforcedPaths: const ['a','b','c'], violationCount: 20);
      expect(a == b, isFalse);
    });
  });

  group('arrarrny/zuraffa_agent#7 - DartIoFreeGate clean-arch layers', () {
    test('DartIoFreeGateProvider is a DartIoFreeGateService', () {
      final provider = DartIoFreeGateProvider();
      expect(provider, isA<DartIoFreeGateService>());
    });

    test('DartIoFreeGateProvider.current returns the active gate', () async {
      final provider = DartIoFreeGateProvider();
      final gate = await provider.current(NoParams());
      expect(gate, isA<DartIoFreeGate>());
      expect(gate.id, 'default');
      expect(gate.gateName, 'dart-io-free');
      expect(gate.enforcedPaths, contains('lib/src'));
      expect(gate.violationCount, 0);
    });

    test('DartIoFreeGateProvider.count returns 1', () async {
      final provider = DartIoFreeGateProvider();
      expect(await provider.count(NoParams()), 1);
    });

    test('DartIoFreeGateProvider honours an injected value object', () async {
      final custom = DartIoFreeGate(
        id: 'custom',
        gateName: 'dart-io-free',
        enforcedPaths: const [],
        violationCount: 2,
      );
      final provider = DartIoFreeGateProvider(custom);
      final gate = await provider.current(NoParams());
      expect(gate.id, 'custom');
      expect(gate.violationCount, 2);
      expect(gate.enforcedPaths, isEmpty);
    });
  });
}
