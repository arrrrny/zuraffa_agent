// Issue #135 — HiveSessionStorage.restore: put-first / delete-stale-after.
//
// The JSONL restore path got the atomic temp+rename treatment in the
// backup PR; the Hive path must not depend on a clear-first window either
// — a crash mid-restore must never leave the box empty (issue #135's
// crash-window theme). This file owns exactly one Hive store: adapters
// register globally per process (registerZuraffaAdapters is not
// idempotent), so one HiveSessionStorage per test file is the convention.

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

void main() {
  final t0 = DateTime.utc(2026, 1, 1, 10);
  final t1 = DateTime.utc(2026, 1, 2, 10);
  final t2 = DateTime.utc(2026, 1, 3, 10);

  late Directory tempDir;
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('zfa_backup_');
    Hive.init(tempDir.path);
  });
  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test(
    'put-first restore deletes stale entries — no clear-first window',
    () async {
      final store = HiveSessionStorage(
        boxName: 'res_${DateTime.now().microsecondsSinceEpoch}',
      );
      await store.init();
      await store.appendEntry(entry('e_0', t0));
      await store.appendEntry(entry('e_1', t1, parent: 'e_0'));
      await store.setActiveLeafId('e_1');
      final dest = '${tempDir.path}/hive_res.jsonl';
      await store.backup(dest);

      // Diverge after the snapshot was taken.
      await store.appendEntry(entry('stale', t2, parent: 'e_1'));
      await store.setActiveLeafId('stale');

      // Restore: the snapshot state returns and the stale entry is gone.
      // The put-first / delete-stale-after order means the box is never
      // emptied before the restored entries land — clear() first would
      // leave an empty box if a crash hit mid-restore (issue #135).
      await store.restore(dest);

      final ids = (await store.getEntries()).map((e) => e.id).toSet();
      expect(ids, {'e_0', 'e_1'});
      expect(await store.getActiveLeafId(), 'e_1');
      await store.close();
    },
  );
}
