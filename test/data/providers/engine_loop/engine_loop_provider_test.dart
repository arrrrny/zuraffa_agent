// HAND-CURATED regression tests for the EngineLoop value object +
// EngineLoopProvider stub. Pattern mirrors spec 033.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/domain/entities/engine_loop/engine_loop.dart';
import 'package:zuraffa_agent/src/domain/services/engine_loop_service.dart';
import 'package:zuraffa_agent/src/data/providers/engine_loop/engine_loop_provider.dart';

void main() {
  group('arrarrny/zuraffa_agent#2 - EngineLoop value equality', () {
    test('EngineLoop equality is value-based across all fields', () {
      final a = EngineLoop(id: 'id-a', sessionId: 'sess-1', maxTurns: 10, wallClockTimeoutMs: 10, repetitionThreshold: 10);
      final b = EngineLoop(id: 'id-a', sessionId: 'sess-1', maxTurns: 10, wallClockTimeoutMs: 10, repetitionThreshold: 10);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('EngineLoop inequality differs when a field changes', () {
      final a = EngineLoop(id: 'id-a', sessionId: 'sess-1', maxTurns: 10, wallClockTimeoutMs: 10, repetitionThreshold: 10);
      final b = EngineLoop(id: 'id-b', sessionId: 'sess-2', maxTurns: 20, wallClockTimeoutMs: 20, repetitionThreshold: 20);
      expect(a == b, isFalse);
    });
  });

  group('arrarrny/zuraffa_agent#2 - EngineLoop clean-arch layers', () {
    test('EngineLoopProvider is a EngineLoopService', () {
      final provider = EngineLoopProvider();
      expect(provider, isA<EngineLoopService>());
    });

    test('EngineLoopProvider.current throws UnimplementedError on NoParams', () {
      final provider = EngineLoopProvider();
      expect(
        () => provider.current(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('EngineLoopProvider.count throws UnimplementedError on NoParams', () {
      final provider = EngineLoopProvider();
      expect(
        () => provider.count(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
