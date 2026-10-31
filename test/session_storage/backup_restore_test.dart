// Issue #135 — SessionStorage.backup / restore + N-generation close backups.
//
// The backup envelope is the versioned session-file format: a `_schema`
// header line (PS-1 / spec 110), a `_backup` provenance line, the `_meta`
// active-leaf line, then one entry line per entry. A backup file is itself
// a valid session file: opening it with JsonlSessionStorage.init() works.

import 'dart:convert';
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

  Future<JsonlSessionStorage> seededJsonl(String path, {String? leaf}) async {
    final store = JsonlSessionStorage(path);
    await store.init();
    await store.appendEntry(entry('e_0', t0));
    await store.appendEntry(entry('e_1', t1, parent: 'e_0'));
    await store.appendEntry(entry('e_2', t2, parent: 'e_1'));
    if (leaf != null) await store.setActiveLeafId(leaf);
    return store;
  }

  group('JsonlSessionStorage.backup', () {
    test('writes a versioned snapshot envelope to dest', () async {
      final store = await seededJsonl('${tempDir.path}/s.jsonl', leaf: 'e_2');
      final dest = '${tempDir.path}/snap.jsonl';

      await store.backup(dest);
      await store.close();

      final lines = await File(dest).readAsLines();
      final nonEmpty = lines.where((l) => l.trim().isNotEmpty).toList();

      // First line: the standard schema header (PS-1 — the backup format
      // carries the schema version).
      final header = jsonDecode(nonEmpty[0]) as Map<String, dynamic>;
      expect(header[SessionSchema.headerKey], isA<Map<String, dynamic>>());
      expect(
        (header[SessionSchema.headerKey] as Map)['schemaVersion'],
        SessionSchema.currentVersion,
      );

      // Second line: the backup provenance envelope.
      final provenance = jsonDecode(nonEmpty[1]) as Map<String, dynamic>;
      expect(provenance['_backup'], true);
      expect(provenance['format'], 'zuraffa/session-backup');
      expect(provenance['createdAt'], isA<String>());
      expect(provenance['entryCount'], 3);

      // Active leaf meta + the three entries.
      final meta = jsonDecode(nonEmpty[2]) as Map<String, dynamic>;
      expect(meta['_meta'], true);
      expect(meta['activeLeafId'], 'e_2');
      expect(nonEmpty.length, 6);
    });

    test('snapshot is atomic — no leftover temp file at dest', () async {
      final store = await seededJsonl('${tempDir.path}/s.jsonl');
      final dest = '${tempDir.path}/snap.jsonl';

      await store.backup(dest);

      expect(File('$dest.tmp').existsSync(), isFalse);
      // The uniquified temp (`dest.tmp.<pid>_<micros>`) is renamed away
      // too — no leftover temp file of any name.
      final leftovers = await Directory(
        tempDir.path,
      ).list().where((e) => e.path.startsWith('$dest.tmp')).toList();
      expect(leftovers, isEmpty);
      expect(File(dest).existsSync(), isTrue);
    });

    test('backup file is directly openable as a session store', () async {
      final store = await seededJsonl('${tempDir.path}/s.jsonl', leaf: 'e_2');
      final dest = '${tempDir.path}/snap.jsonl';
      await store.backup(dest);

      final reopened = JsonlSessionStorage(dest);
      final result = await reopened.init();
      expect(result.tearReport, isNull);
      expect(result.loadedEntriesCount, 3);
      expect(await reopened.getActiveLeafId(), 'e_2');
      final ids = (await reopened.getEntries()).map((e) => e.id).toSet();
      expect(ids, {'e_0', 'e_1', 'e_2'});
    });
  });

  group('JsonlSessionStorage.restore', () {
    test('replaces current state with the snapshot', () async {
      final source = await seededJsonl(
        '${tempDir.path}/src.jsonl',
        leaf: 'e_2',
      );
      final dest = '${tempDir.path}/snap.jsonl';
      await source.backup(dest);

      // A different, diverged store restores the snapshot.
      final target = await seededJsonl(
        '${tempDir.path}/tgt.jsonl',
        leaf: 'e_0',
      );
      await target.appendEntry(entry('other', t2));

      await target.restore(dest);

      final entries = await target.getEntries();
      expect(entries.map((e) => e.id).toSet(), {'e_0', 'e_1', 'e_2'});
      expect(await target.getActiveLeafId(), 'e_2');
      await target.close();

      // Restore is durable immediately — a fresh instance sees it.
      final reopened = JsonlSessionStorage('${tempDir.path}/tgt.jsonl');
      await reopened.init();
      expect((await reopened.getEntries()).length, 3);
      expect(await reopened.getActiveLeafId(), 'e_2');
      await reopened.close();
    });

    test('rejects a backup newer than the supported schema version', () async {
      final store = await seededJsonl('${tempDir.path}/s.jsonl');
      final dest = '${tempDir.path}/future.jsonl';
      await store.backup(dest);

      final lines = await File(dest).readAsLines();
      lines[0] = jsonEncode({
        SessionSchema.headerKey: {
          'schemaVersion': SessionSchema.currentVersion + 1,
        },
      });
      await File(dest).writeAsString(lines.join('\n'));

      expect(() => store.restore(dest), throwsA(isA<StateError>()));
    });

    test('a header without schemaVersion throws FormatException', () async {
      final store = await seededJsonl('${tempDir.path}/s.jsonl');
      final dest = '${tempDir.path}/noschema.jsonl';
      await store.backup(dest);

      final lines = await File(dest).readAsLines();
      lines[0] = jsonEncode({SessionSchema.headerKey: <String, dynamic>{}});
      await File(dest).writeAsString(lines.join('\n'));

      expect(() => store.restore(dest), throwsA(isA<FormatException>()));
    });

    test('accepts a legacy-versioned backup and migrates it', () async {
      final store = await seededJsonl('${tempDir.path}/s.jsonl');
      final dest = '${tempDir.path}/legacy.jsonl';
      await store.backup(dest);

      final lines = await File(dest).readAsLines();
      lines[0] = jsonEncode({
        SessionSchema.headerKey: {'schemaVersion': 1},
      });
      await File(dest).writeAsString(lines.join('\n'));

      await store.restore(dest);
      expect((await store.getEntries()).length, 3);
    });

    test('restores into an empty store that never held entries', () async {
      final source = await seededJsonl(
        '${tempDir.path}/src.jsonl',
        leaf: 'e_1',
      );
      final dest = '${tempDir.path}/snap.jsonl';
      await source.backup(dest);

      final emptyPath = '${tempDir.path}/empty.jsonl';
      final empty = JsonlSessionStorage(emptyPath);
      await empty.init();

      await empty.restore(dest);
      expect((await empty.getEntries()).length, 3);
      expect(await empty.getActiveLeafId(), 'e_1');
      await empty.close();
    });
  });

  group('cross-backend backups', () {
    test('InMemory backup restores into JsonlSessionStorage', () async {
      final memory = InMemorySessionStorage();
      await memory.init();
      await memory.appendEntry(entry('e_0', t0));
      await memory.appendEntry(entry('e_1', t1, parent: 'e_0'));
      await memory.setActiveLeafId('e_1');
      final dest = '${tempDir.path}/mem.jsonl';
      await memory.backup(dest);

      final jsonl = JsonlSessionStorage('${tempDir.path}/tgt.jsonl');
      await jsonl.init();
      await jsonl.restore(dest);

      expect((await jsonl.getEntries()).length, 2);
      expect(await jsonl.getActiveLeafId(), 'e_1');
    });

    test('Hive backup restores into InMemorySessionStorage', () async {
      final hive = HiveSessionStorage(
        boxName: 'bk_${DateTime.now().microsecondsSinceEpoch}',
      );
      await hive.init();
      await hive.appendEntry(entry('e_0', t0));
      await hive.appendEntry(entry('e_1', t1, parent: 'e_0'));
      await hive.setActiveLeafId('e_1');
      final dest = '${tempDir.path}/hive.jsonl';
      await hive.backup(dest);

      final memory = InMemorySessionStorage();
      await memory.restore(dest);

      final ids = (await memory.getEntries()).map((e) => e.id).toSet();
      expect(ids, {'e_0', 'e_1'});
      expect(await memory.getActiveLeafId(), 'e_1');
    });
  });

  group('N-generation close backups (JSONL)', () {
    test('disabled by default — close writes no backup files', () async {
      final store = await seededJsonl('${tempDir.path}/s.jsonl');
      await store.appendEntry(entry('e_3', t2, parent: 'e_2'));
      await store.close();

      expect(File('${tempDir.path}/s.jsonl.backup.1').existsSync(), isFalse);
    });

    test('close rotates backup generations when enabled', () async {
      final path = '${tempDir.path}/s.jsonl';
      final first = JsonlSessionStorage(path, backupGenerations: 2);
      await first.init();
      await first.appendEntry(entry('e_0', t0));
      await first.close();

      final one = File('$path.backup.1');
      expect(one.existsSync(), isTrue);
      final gen1 = await one.readAsString();

      // Second mission: a new entry lands, close rotates generation 1 → 2.
      final second = JsonlSessionStorage(path, backupGenerations: 2);
      await second.init();
      await second.appendEntry(entry('e_1', t1, parent: 'e_0'));
      await second.close();

      expect(File('$path.backup.2').existsSync(), isTrue);
      // Generation 2 holds the FIRST close's snapshot, byte for byte.
      expect(await File('$path.backup.2').readAsString(), gen1);
      // Generation 1 holds the newest close's snapshot (both entries).
      final gen1Lines = await File('$path.backup.1').readAsLines();
      final entryLines = gen1Lines
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .map((l) => jsonDecode(l) as Map<String, dynamic>)
          .where(
            (m) =>
                !m.containsKey('_schema') &&
                !m.containsKey('_meta') &&
                !m.containsKey('_backup'),
          )
          .toList();
      expect(entryLines.length, 2);
    });

    test('no-op close (not dirty) does not rotate generations', () async {
      final path = '${tempDir.path}/s.jsonl';
      final store = JsonlSessionStorage(path, backupGenerations: 3);
      await store.init();
      await store.close();

      expect(File('$path.backup.1').existsSync(), isFalse);
    });
  });
}
