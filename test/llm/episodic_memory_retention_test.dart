// Issue #135 — RetentionPolicy + prune() on the episodic memory stores.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/episodic_memory/episodic_memory.dart';
import 'package:zuraffa_agent/src/llm/episodic_memory_store.dart';
import 'package:zuraffa_agent/src/llm/persistent_episodic_memory_store.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

EpisodicMemory memory(String id, String summary) =>
    EpisodicMemory(id: id, summary: summary, messages: const []);

void main() {
  final t0 = DateTime.utc(2026, 1, 1);
  final t1 = DateTime.utc(2026, 1, 5);
  final t2 = DateTime.utc(2026, 1, 10);
  final now = DateTime.utc(2026, 1, 16);
  // cutoff = now - 6 days = 2026-01-10: t0/t1 prune, t2 survives.
  const old_ = RetentionPolicy(maxAge: Duration(days: 6));

  group('EpisodicMemoryStore.prune', () {
    test('maxAge drops memories recorded before the cutoff', () async {
      final store = EpisodicMemoryStore();
      store.add(memory('m0', 'old'), at: t0);
      store.add(memory('m1', 'mid'), at: t1);
      store.add(memory('m2', 'new'), at: t2);

      final result = await store.prune(old_, now: now);

      expect(result.removedCount, 2);
      expect(store.retrieve('m0'), isNull);
      expect(store.retrieve('m1'), isNull);
      expect(store.retrieve('m2'), isNotNull);
      expect(store.entries.map((m) => m.id), ['m2']);
    });

    test('maxCount keeps the newest memories', () async {
      final store = EpisodicMemoryStore();
      store.add(memory('m0', 'a'), at: t0);
      store.add(memory('m1', 'b'), at: t1);
      store.add(memory('m2', 'c'), at: t2);

      final result = await store.prune(
        const RetentionPolicy(maxCount: 1),
        now: now,
      );

      expect(result.removedCount, 2);
      expect(store.entries.map((m) => m.id), ['m2']);
    });

    test('re-added memory gets a fresh recording time', () async {
      final store = EpisodicMemoryStore();
      store.add(memory('m0', 'old body'), at: t0);
      store.add(memory('m0', 'refreshed body'), at: t2);

      await store.prune(old_, now: now);

      expect(store.retrieve('m0'), isNotNull);
      expect(store.retrieve('m0')!.summary, 'refreshed body');
    });

    test('unlimited policy prunes nothing', () async {
      final store = EpisodicMemoryStore();
      store.add(memory('m0', 'a'), at: t0);

      final result = await store.prune(
        const RetentionPolicy.unlimited(),
        now: now,
      );

      expect(result.removedCount, 0);
      expect(store.entries.length, 1);
    });
  });

  group('PersistentEpisodicMemoryStore.prune', () {
    test('removes the mirrored custom entries from storage too', () async {
      final storage = InMemorySessionStorage();
      await storage.init();
      final store = PersistentEpisodicMemoryStore(storage: storage);
      await store.add(memory('m0', 'old'));
      await store.add(memory('m1', 'new'));

      final result = await store.prune(const RetentionPolicy(maxCount: 1));

      expect(result.removedCount, 1);
      expect(store.retrieve('m0'), isNull);
      expect(store.retrieve('m1'), isNotNull);

      final storageIds = (await storage.getEntries())
          .whereType<CustomTreeEntry>()
          .where((e) => e.record.customType == kEpisodicMemoryCustomType)
          .map((e) => e.id)
          .toSet();
      expect(storageIds, {'m1'});
    });

    test(
      'restore() carries storage timestamps so maxAge works after restart',
      () async {
        final storage = InMemorySessionStorage();
        await storage.init();
        final store = PersistentEpisodicMemoryStore(storage: storage);
        await store.add(memory('m0', 'old'), at: t0);
        await store.add(memory('m1', 'new'), at: t2);

        // Engine restart: a fresh store rebuilds from storage.
        final reborn = PersistentEpisodicMemoryStore(storage: storage);
        await reborn.restore();

        final result = await reborn.prune(old_, now: now);
        expect(result.removedCount, 1);
        expect(reborn.retrieve('m0'), isNull);
        expect(reborn.retrieve('m1'), isNotNull);
      },
    );
  });
}
