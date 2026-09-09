// spec 110 (issue #122) — Hive meta-box schema-version stamp.

import 'dart:io';

import 'package:hive_ce/hive.dart';
import 'package:test/test.dart';
import 'package:zuraffa_agent/src/hive_session_store.dart';
import 'package:zuraffa_agent/src/session_storage.dart';

void main() {
  late Directory tempDir;
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('zfa_hive_');
    Hive.init(tempDir.path);
  });
  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('U9: a fresh Hive store stamps the meta-box schema version', () async {
    final store = HiveSessionStorage(
      boxName: 'schema_version_${DateTime.now().microsecondsSinceEpoch}',
    );
    final result = await store.init();

    expect(result.schemaVersion, SessionSchema.currentVersion);
    expect(result.loadedEntriesCount, 0);

    // The stamp is observable in the meta box.
    final meta = await Hive.openBox<String>('_zuraffa_meta');
    expect(
      int.parse(meta.get('schemaVersion')!),
      SessionSchema.currentVersion,
    );
  });
}
