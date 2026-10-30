// Issue #135 — RetentionPolicy + prune() on SessionStorage implementations.
//
// Policy axes: maxAge (entries older than the cutoff drop), maxCount (the
// NEWEST maxCount entries survive), maxBytes (oldest-first until the
// serialized size fits). The active-leaf pointer is cleared when its entry
// is pruned. JSONL/Hive prunes are durable: a fresh instance sees the
// pruned state.

import 'dart:io';

import 'package:hive_ce/hive.dart';
import 'package:test/test.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

MessageEntry entry(String id, DateTime at, {String? parent}) => MessageEntry(
  id: id,
  parentId: parent,
  timestamp: at,
  message: UserMessage.text('msg-$id'),
);

// cutoff = now - 6 days = 2026-01-10: t0/t1 prune, t2 sits exactly at
// the cutoff and survives (the age rule is strictly-older).
const old_ = RetentionPolicy(maxAge: Duration(days: 6));

void main() {
  final t0 = DateTime.utc(2026, 1, 1);
  final t1 = DateTime.utc(2026, 1, 5);
  final t2 = DateTime.utc(2026, 1, 10);
  final t3 = DateTime.utc(2026, 1, 15);
  final now = DateTime.utc(2026, 1, 16);

  late Directory tempDir;
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('zfa_retention_');
    Hive.init(tempDir.path);
  });
  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  Future<void> seedFour(SessionStorage store) async {
    await store.init();
    await store.appendEntry(entry('old', t0));
    await store.appendEntry(entry('mid', t1, parent: 'old'));
    await store.appendEntry(entry('new', t2, parent: 'mid'));
    await store.appendEntry(entry('newest', t3, parent: 'new'));
    await store.setActiveLeafId('newest');
  }

  group('prune — maxAge', () {
    for (final (label, make) in [
      ('InMemorySessionStorage', () => InMemorySessionStorage()),
      (
        'JsonlSessionStorage',
        () => JsonlSessionStorage(
          '${tempDir.path}/age_${DateTime.now().microsecondsSinceEpoch}.jsonl',
        ),
      ),
    ]) {
      test('$label drops entries older than the cutoff', () async {
        final store = make();
        await store.init();
        await seedFour(store);

        final result = await store.prune(old_, now: now);

        expect(result.removedCount, 2);
        expect((await store.getEntries()).map((e) => e.id).toSet(), {
          'new',
          'newest',
        });
        // The active leaf survived — the pointer is intact.
        expect(await store.getActiveLeafId(), 'newest');
      });
    }
  });

  test('InMemorySessionStorage prune — maxCount keeps the newest', () async {
    final store = InMemorySessionStorage();
    await seedFour(store);

    final result = await store.prune(
      const RetentionPolicy(maxCount: 2),
      now: now,
    );

    expect(result.removedCount, 2);
    expect((await store.getEntries()).map((e) => e.id).toSet(), {
      'new',
      'newest',
    });
  });

  test('InMemorySessionStorage prune — maxBytes drops oldest first', () async {
    final store = InMemorySessionStorage();
    await store.init();
    await store.appendEntry(entry('big-old', t0, parent: null));
    await store.appendEntry(entry('small-old', t1, parent: 'big-old'));
    await store.appendEntry(entry('newest', t3, parent: 'small-old'));

    // Budget that fits the newest entry plus a little: the biggest old
    // entry goes first regardless of age ordering ties.
    final result = await store.prune(
      const RetentionPolicy(maxBytes: 220),
      now: now,
    );

    expect(result.removedCount, greaterThanOrEqualTo(1));
    expect(result.removedBytes, greaterThanOrEqualTo(0));
    final kept = (await store.getEntries()).map((e) => e.id).toSet();
    expect(kept, contains('newest'));
    expect(
      kept.contains('big-old'),
      isFalse,
      reason: 'the largest oldest entry is dropped first',
    );
  });

  test('unlimited policy prunes nothing', () async {
    final store = InMemorySessionStorage();
    await seedFour(store);

    final result = await store.prune(
      const RetentionPolicy.unlimited(),
      now: now,
    );

    expect(result.removedCount, 0);
    expect(result.removedBytes, 0);
    expect((await store.getEntries()).length, 4);
  });

  test('active-leaf pointer is cleared when its entry is pruned', () async {
    final store = InMemorySessionStorage();
    await seedFour(store);
    await store.setActiveLeafId('old');

    await store.prune(old_, now: now);

    expect(await store.getActiveLeafId(), isNull);
  });

  test('JSONL prune is durable across a fresh open', () async {
    final path = '${tempDir.path}/durable.jsonl';
    final store = JsonlSessionStorage(path);
    await seedFour(store);

    await store.prune(const RetentionPolicy(maxCount: 2), now: now);
    await store.close();

    final reopened = JsonlSessionStorage(path);
    final open = await reopened.init();
    expect(open.loadedEntriesCount, 2);
    expect((await reopened.getEntries()).map((e) => e.id).toSet(), {
      'new',
      'newest',
    });
    await reopened.close();
  });

  test('HiveSessionStorage prune enforces the policy', () async {
    final hive = HiveSessionStorage(
      boxName: 'ret_${DateTime.now().microsecondsSinceEpoch}',
    );
    await seedFour(hive);

    final result = await hive.prune(
      const RetentionPolicy(maxCount: 2),
      now: now,
    );

    expect(result.removedCount, 2);
    final ids = (await hive.getEntries()).map((e) => e.id).toSet();
    expect(ids, {'new', 'newest'});
  });
}
