// HAND-CURATED regression tests for the CompactionStrategy value object +
// CompactionStrategyProvider stub. Pattern mirrors spec 033.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/domain/entities/compaction_strategy/compaction_strategy.dart';
import 'package:zuraffa_agent/src/domain/services/compaction_strategy_service.dart';
import 'package:zuraffa_agent/src/data/providers/compaction_strategy/compaction_strategy_provider.dart';

void main() {
  group('arrarrny/zuraffa_agent#3 - CompactionStrategy value equality', () {
    test('CompactionStrategy equality is value-based across all fields', () {
      final a = CompactionStrategy(id: 'id-a', sessionId: 'sess-1', retainEntryIds: const ['a','b'], summarizeEntryIds: const ['a','b'], artifactRefs: const ['a','b'], compactedAt: 10);
      final b = CompactionStrategy(id: 'id-a', sessionId: 'sess-1', retainEntryIds: const ['a','b'], summarizeEntryIds: const ['a','b'], artifactRefs: const ['a','b'], compactedAt: 10);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('CompactionStrategy inequality differs when a field changes', () {
      final a = CompactionStrategy(id: 'id-a', sessionId: 'sess-1', retainEntryIds: const ['a','b'], summarizeEntryIds: const ['a','b'], artifactRefs: const ['a','b'], compactedAt: 10);
      final b = CompactionStrategy(id: 'id-b', sessionId: 'sess-2', retainEntryIds: const ['a','b','c'], summarizeEntryIds: const ['a','b','c'], artifactRefs: const ['a','b','c'], compactedAt: 20);
      expect(a == b, isFalse);
    });
  });

  group('arrarrny/zuraffa_agent#3 - CompactionStrategy clean-arch layers', () {
    test('CompactionStrategyProvider is a CompactionStrategyService', () {
      final provider = CompactionStrategyProvider();
      expect(provider, isA<CompactionStrategyService>());
    });

    test('CompactionStrategyProvider.current returns the active strategy', () async {
      final strategy = await CompactionStrategyProvider().current(NoParams());
      expect(strategy, isA<CompactionStrategy>());
      expect(strategy.id, 'selective');
      expect(strategy.sessionId, '');
      expect(strategy.retainEntryIds, isEmpty);
      expect(strategy.summarizeEntryIds, isEmpty);
      expect(strategy.artifactRefs, isEmpty);
      expect(strategy.compactedAt, 0);
    });

    test('CompactionStrategyProvider honors an injected active strategy', () async {
      final injected = CompactionStrategy(
        id: 'custom',
        sessionId: 'sess-x',
        retainEntryIds: const ['e1'],
        summarizeEntryIds: const ['e2'],
        artifactRefs: const ['a1'],
        compactedAt: 42,
      );
      final strategy = await CompactionStrategyProvider(injected).current(NoParams());
      expect(strategy, same(injected));
    });

    test('CompactionStrategyProvider.count returns 1', () async {
      expect(await CompactionStrategyProvider().count(NoParams()), 1);
    });
  });
}
