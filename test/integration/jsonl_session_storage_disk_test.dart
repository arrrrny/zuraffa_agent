// Integration — issue #113: JSONL session storage ROUND-TRIP ON DISK.
//
// The JsonlSessionStorage coverage in test/session_storage_test.dart stops at
// the unit level: it proves entries land in the file and the active-leaf
// pointer survives a close/reopen, but it never re-opens a store and asserts
// that the ENTRIES THEMSELVES — ids, parent links, message payload content,
// and the schema header — come back intact. This test is that full
// round-trip, against a real temp directory on disk:
//
//   write (append-only streaming, no close) -> close (atomic rewrite)
//     -> fresh instance on the SAME path (simulated process restart)
//       -> every field compared -> append continues across the restart.
//
// Tagged `integration` so `dart test -P integration` (the nightly lane,
// issue #113) selects it; the default `dart test` run still executes it —
// it is hermetic (system temp dir, no network, no secrets).

@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

/// Flattens a (possibly JSON-round-tripped) content-block payload into text.
String _messageText(AgentMessage message) {
  final content = message.toJson()['content'];
  if (content is String) return content;
  if (content is! List) return '';
  return [
    for (final block in content)
      if (block is Map && block['text'] is String) block['text'] as String,
  ].join('\n');
}

void main() {
  group('JsonlSessionStorage disk round-trip (issue #113)', () {
    late Directory tmpDir;
    late String storePath;
    final t0 = DateTime.utc(2026, 1, 15, 12, 0, 0);

    setUp(() async {
      tmpDir = await Directory.systemTemp.createTemp('zfa_jsonl_roundtrip_');
      storePath = '${tmpDir.path}/session.jsonl';
    });

    tearDown(() async {
      if (await tmpDir.exists()) await tmpDir.delete(recursive: true);
    });

    test(
      'entries, payload content, and active leaf survive close/reopen',
      () async {
        // --- Session 1: write a three-message branch (streaming appends).
        final store = JsonlSessionStorage(storePath);
        final firstOpen = await store.init();
        expect(firstOpen.loadedEntriesCount, 0);
        expect(firstOpen.tearReport, isNull);
        expect(firstOpen.schemaVersion, SessionSchema.currentVersion);

        await store.appendEntry(
          MessageEntry(
            id: 'e_1',
            timestamp: t0,
            message: UserMessage.text('hello'),
          ),
        );
        await store.appendEntry(
          MessageEntry(
            id: 'e_2',
            parentId: 'e_1',
            timestamp: t0,
            message: AssistantMessage.text('hi there'),
          ),
        );
        await store.appendEntry(
          MessageEntry(
            id: 'e_3',
            parentId: 'e_2',
            timestamp: t0,
            message: UserMessage.text('run the numbers'),
          ),
        );
        await store.setActiveLeafId('e_3');

        // Streaming append is DURABLE BEFORE close: header + 3 entry lines
        // are already on disk (the crash window issue #135 closed).
        final preCloseLines = (await File(storePath).readAsLines())
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();
        expect(preCloseLines, hasLength(4));
        expect(
          jsonDecode(
            preCloseLines.first,
          )[SessionSchema.headerKey]['schemaVersion'],
          SessionSchema.currentVersion,
        );

        await store.close();

        // The close flushed dirty state: the rewrite carries the schema
        // header, the active-leaf meta line, and the entries.
        final postCloseLines = (await File(storePath).readAsLines())
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();
        expect(jsonDecode(postCloseLines[1])['_meta'], isTrue);
        expect(jsonDecode(postCloseLines[1])['activeLeafId'], 'e_3');

        // --- Session 2: a FRESH instance against the SAME path — the
        // simulated process restart. Every field must come back.
        final reopened = JsonlSessionStorage(storePath);
        final reopen = await reopened.init();
        expect(reopen.loadedEntriesCount, 3);
        expect(reopen.tearReport, isNull);
        expect(reopen.schemaVersion, SessionSchema.currentVersion);
        expect(await reopened.getActiveLeafId(), 'e_3');

        final loaded = await reopened.getEntries();
        expect(loaded.map((e) => e.id).toSet(), {'e_1', 'e_2', 'e_3'});

        final byId = {
          for (final entry in loaded) entry.id: entry as MessageEntry,
        };
        // Parent links re-attach the branch.
        expect(byId['e_2']!.parentId, 'e_1');
        expect(byId['e_3']!.parentId, 'e_2');
        // PAYLOAD CONTENT round-trips (the gap the unit suite left): roles and
        // message text must be byte-identical through the JSONL encoding.
        expect(_messageText(byId['e_1']!.message), 'hello');
        expect(byId['e_1']!.message, isA<UserMessage>());
        expect(_messageText(byId['e_2']!.message), 'hi there');
        expect(byId['e_2']!.message, isA<AssistantMessage>());
        expect(_messageText(byId['e_3']!.message), 'run the numbers');
        // Entry-level timestamps survive the ISO-8601 round-trip.
        expect(byId['e_1']!.timestamp, t0);

        // --- The branch keeps growing across the restart.
        await reopened.appendEntry(
          MessageEntry(
            id: 'e_4',
            parentId: 'e_3',
            timestamp: t0,
            message: AssistantMessage.text('sum=5'),
          ),
        );
        await reopened.setActiveLeafId('e_4');
        await reopened.close();

        final third = JsonlSessionStorage(storePath);
        final thirdOpen = await third.init();
        expect(thirdOpen.loadedEntriesCount, 4);
        expect(thirdOpen.tearReport, isNull);
        expect(await third.getActiveLeafId(), 'e_4');
        final e4 = (await third.getEntry('e_4'))! as MessageEntry;
        expect(e4.parentId, 'e_3');
        expect(_messageText(e4.message), 'sum=5');
        await third.close();
      },
    );
  });
}
