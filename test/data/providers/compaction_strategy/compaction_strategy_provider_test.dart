// HAND-CURATED regression tests for the CompactionStrategy value object +
// CompactionStrategyProvider stub. Pattern mirrors spec 033.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/data/providers/compaction_strategy/compaction_strategy_provider.dart';
import 'package:zuraffa_agent/src/domain/entities/compaction_strategy/compaction_strategy.dart';
import 'package:zuraffa_agent/src/domain/services/compaction_strategy_service.dart';

void main() {
  group('arrarrny/zuraffa_agent#3 - CompactionStrategy value equality', () {
    test('CompactionStrategy equality is value-based across all fields', () {
      const a = CompactionStrategy(
        id: 'id-a',
        sessionId: 'sess-1',
        retainEntryIds: ['a', 'b'],
        summarizeEntryIds: ['a', 'b'],
        artifactRefs: ['a', 'b'],
        compactedAt: 10,
      );
      const b = CompactionStrategy(
        id: 'id-a',
        sessionId: 'sess-1',
        retainEntryIds: ['a', 'b'],
        summarizeEntryIds: ['a', 'b'],
        artifactRefs: ['a', 'b'],
        compactedAt: 10,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('CompactionStrategy inequality differs when a field changes', () {
      const a = CompactionStrategy(
        id: 'id-a',
        sessionId: 'sess-1',
        retainEntryIds: ['a', 'b'],
        summarizeEntryIds: ['a', 'b'],
        artifactRefs: ['a', 'b'],
        compactedAt: 10,
      );
      const b = CompactionStrategy(
        id: 'id-b',
        sessionId: 'sess-2',
        retainEntryIds: ['a', 'b', 'c'],
        summarizeEntryIds: ['a', 'b', 'c'],
        artifactRefs: ['a', 'b', 'c'],
        compactedAt: 20,
      );
      expect(a == b, isFalse);
    });
  });

  group('arrarrny/zuraffa_agent#3 - CompactionStrategy clean-arch layers', () {
    test('CompactionStrategyProvider is a CompactionStrategyService', () {
      final provider = CompactionStrategyProvider();
      expect(provider, isA<CompactionStrategyService>());
    });

    test(
      'CompactionStrategyProvider.current returns the active strategy',
      () async {
        final strategy = await CompactionStrategyProvider().current(
          const NoParams(),
        );
        expect(strategy, isA<CompactionStrategy>());
        expect(strategy.id, 'selective');
        expect(strategy.sessionId, '');
        expect(strategy.retainEntryIds, isEmpty);
        expect(strategy.summarizeEntryIds, isEmpty);
        expect(strategy.artifactRefs, isEmpty);
        expect(strategy.compactedAt, 0);
      },
    );

    test(
      'CompactionStrategyProvider honors an injected active strategy',
      () async {
        const injected = CompactionStrategy(
          id: 'custom',
          sessionId: 'sess-x',
          retainEntryIds: ['e1'],
          summarizeEntryIds: ['e2'],
          artifactRefs: ['a1'],
          compactedAt: 42,
        );
        final strategy = await CompactionStrategyProvider(
          injected,
        ).current(const NoParams());
        expect(strategy, same(injected));
      },
    );

    test('CompactionStrategyProvider.count returns 1', () async {
      expect(await CompactionStrategyProvider().count(const NoParams()), 1);
    });
  });
}
