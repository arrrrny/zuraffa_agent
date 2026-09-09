// spec 110 (issue #122) — SessionMigrator registry + JSONL versioning.

import 'dart:io';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/session_migrator.dart';
import 'package:zuraffa_agent/src/session_storage.dart';
import 'package:zuraffa_agent/src/jsonl_session_storage.dart';
import 'package:zuraffa_agent/src/types.dart';

/// A v1 legacy entry map: no schemaVersion stamp anywhere.
Map<String, dynamic> v1Entry(String id) => {
  '_type': 'message',
  'id': id,
  'timestamp': '2026-01-01T00:00:00.000Z',
  'message': {'role': 'user', 'content': 'hello from v1'},
};

Future<File> writeV1Fixture(String path) async {
  final file = File(path);
  final sink = file.openWrite(mode: FileMode.write);
  sink.writeln(
    '{"_type":"message","id":"e1","timestamp":'
    '"2026-01-01T00:00:00.000Z","message":{"role":"user",'
    '"content":"hello from v1"}}',
  );
  sink.writeln(
    '{"_type":"message","id":"e2","timestamp":'
    '"2026-01-01T00:00:01.000Z","message":{"role":"assistant",'
    '"content":"hi"}}',
  );
  await sink.flush();
  await sink.close();
  return file;
}

void main() {
  group('spec 110 — SessionMigrator registry (issue #122)', () {
    test('U1: a v1 raw entry map migrates through both steps to current', () {
      final migrated = SessionMigrator.standard().migrate(v1Entry('e1'));
      expect(migrated['schemaVersion'], SessionSchema.currentVersion);
      expect(migrated['_type'], 'message');
      expect(migrated['id'], 'e1');
    });

    test('U2: a map already at the current version is returned unchanged', () {
      final current = v1Entry('e1')..['schemaVersion'] = 3;
      final migrated = SessionMigrator.standard().migrate(current);
      expect(migrated['schemaVersion'], 3);
      expect(identical(migrated, current), isTrue);
    });

    test('U3: an entry-map version greater than current is rejected', () {
      final future = v1Entry('e1')..['schemaVersion'] = 99;
      expect(
        () => SessionMigrator.standard().migrate(future),
        throwsA(
          predicate((Object e) => e is StateError && e.message.contains('99')),
        ),
      );
    });
  });

  group('spec 110 — JSONL schema versioning (issue #122)', () {
    late Directory tempDir;
    late String path;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('zfa_schema_');
      path = '${tempDir.path}/session.jsonl';
    });
    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('A1: a v1 fixture migrates to v3 in memory and on disk', () async {
      await writeV1Fixture(path);
      final storage = JsonlSessionStorage(path);

      final result = await storage.init();
      expect(result.schemaVersion, SessionSchema.currentVersion);
      expect(result.migratedFromVersion, 1);
      expect(result.loadedEntriesCount, 2);

      // Every entry deserialized into memory.
      final entries = await storage.getEntries();
      expect(entries.map((e) => e.id).toSet(), {'e1', 'e2'});

      // The file on disk now carries the v3 header as its first line.
      final firstLine = await File(path).readAsLines().then((l) => l.first);
      expect(firstLine, contains('"schemaVersion"'));
      expect(firstLine, contains('${SessionSchema.currentVersion}'));
    });

    test('U5: the header line is not surfaced as an entry', () async {
      await writeV1Fixture(path);
      final storage = JsonlSessionStorage(path);
      await storage.init();
      final entries = await storage.getEntries();
      expect(entries, hasLength(2));
      expect(entries.every((e) => e.id != 'schema'), isTrue);
    });

    test('U6: a current-version file opens with no migration', () async {
      final storage = JsonlSessionStorage(path);
      await storage.init(); // fresh → header written
      await storage.appendEntry(
        v1Entry('e1').let((m) {
          m['schemaVersion'] = 3;
          return SessionTreeEntry.fromJson(m);
        }),
      );

      final reopened = JsonlSessionStorage(path);
      final result = await reopened.init();
      expect(result.schemaVersion, SessionSchema.currentVersion);
      expect(result.migratedFromVersion, isNull);
      expect(result.loadedEntriesCount, 1);
    });

    test(
      'U7: a file at a future version fails the open with a clear error',
      () async {
        final sink = File(path).openWrite(mode: FileMode.write);
        sink.writeln('{"_schema":{"schemaVersion":99}}');
        await sink.flush();
        await sink.close();

        final storage = JsonlSessionStorage(path);
        await expectLater(
          storage.init(),
          throwsA(
            predicate(
              (Object e) => e is StateError && e.message.contains('99'),
            ),
          ),
        );
      },
    );

    test(
      'U8: a fresh (non-existent) store writes the header on init',
      () async {
        final storage = JsonlSessionStorage(path);
        final result = await storage.init();
        expect(result.schemaVersion, SessionSchema.currentVersion);
        expect(result.migratedFromVersion, isNull);
        final firstLine = await File(path).readAsLines().then((l) => l.first);
        expect(firstLine, contains('schemaVersion'));
      },
    );

    test('U8b: a corrupt first line keeps the tear-report contract', () async {
      final sink = File(path).openWrite(mode: FileMode.write);
      sink.writeln('this is not json at all');
      sink.writeln(
        '{"_type":"message","id":"e9","timestamp":'
        '"2026-01-01T00:00:00.000Z","message":{"role":"user",'
        '"content":"v1 entry after the garbage"}}',
      );
      await sink.flush();
      await sink.close();

      final storage = JsonlSessionStorage(path);
      final result = await storage.init();
      expect(result.tearReport?.lineNumber, 1);
      expect(result.schemaVersion, SessionSchema.currentVersion);
      expect(result.migratedFromVersion, 1);
    });
  });
}

extension _Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}

// PR #146 review finding — a corrupt FIRST line keeps the tear-report
// contract instead of escaping as an untyped exception.
