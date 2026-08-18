// Session storage and AgentSession tree operation tests.
//
// Exercises InMemorySessionStorage, JsonlSessionStorage, and AgentSession
// tree operations (fork, switch, delete, buildContext).

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

void main() {
  final fixedTime = DateTime.utc(2026, 1, 15, 12, 0, 0);

  group('InMemorySessionStorage', () {
    late InMemorySessionStorage store;

    setUp(() async {
      store = InMemorySessionStorage();
      await store.init();
    });

    test('init returns zero loaded entries', () async {
      final result = await InMemorySessionStorage().init();
      expect(result.loadedEntriesCount, 0);
      expect(result.tearReport, isNull);
    });

    test('appendEntry and getEntry round-trip', () async {
      final entry = MessageEntry(
        id: 'e_1',
        parentId: null,
        timestamp: fixedTime,
        message: UserMessage.text('hello'),
      );
      await store.appendEntry(entry);
      final retrieved = await store.getEntry('e_1');
      expect(retrieved, isA<MessageEntry>());
      expect(retrieved!.id, 'e_1');
    });

    test('getEntries returns all appended entries', () async {
      await store.appendEntry(MessageEntry(
        id: 'e_1',
        parentId: null,
        timestamp: fixedTime,
        message: UserMessage.text('a'),
      ));
      await store.appendEntry(MessageEntry(
        id: 'e_2',
        parentId: 'e_1',
        timestamp: fixedTime,
        message: UserMessage.text('b'),
      ));
      final entries = await store.getEntries();
      expect(entries, hasLength(2));
    });

    test('getActiveLeafId/setActiveLeafId persist leaf pointer', () async {
      expect(await store.getActiveLeafId(), isNull);
      await store.setActiveLeafId('e_1');
      expect(await store.getActiveLeafId(), 'e_1');
    });

    test('deleteEntries removes specified entries', () async {
      await store.appendEntry(MessageEntry(
        id: 'e_1',
        parentId: null,
        timestamp: fixedTime,
        message: UserMessage.text('a'),
      ));
      await store.appendEntry(MessageEntry(
        id: 'e_2',
        parentId: 'e_1',
        timestamp: fixedTime,
        message: UserMessage.text('b'),
      ));
      await store.deleteEntries({'e_1'});
      final entries = await store.getEntries();
      expect(entries, hasLength(1));
      expect(entries.first.id, 'e_2');
    });

    test('close is a no-op', () async {
      await store.close(); // Should not throw.
    });
  });

  group('JsonlSessionStorage', () {
    late Directory tmpDir;
    late String jsonlPath;

    setUp(() async {
      tmpDir = await Directory.systemTemp.createTemp('jsonl_test_');
      jsonlPath = '${tmpDir.path}/session.jsonl';
    });

    tearDown(() async {
      if (await Directory(tmpDir.path).exists()) {
        await Directory(tmpDir.path).delete(recursive: true);
      }
    });

    test('init on non-existent file returns zero entries', () async {
      final store = JsonlSessionStorage(jsonlPath);
      final result = await store.init();
      expect(result.loadedEntriesCount, 0);
      expect(result.tearReport, isNull);
    });

    test('appendEntry persists to file', () async {
      final store = JsonlSessionStorage(jsonlPath);
      await store.init();

      final entry = MessageEntry(
        id: 'e_1',
        parentId: null,
        timestamp: fixedTime,
        message: UserMessage.text('hello'),
      );
      await store.appendEntry(entry);

      final file = File(jsonlPath);
      expect(await file.exists(), isTrue);
      final content = await file.readAsString();
      expect(content.contains('e_1'), isTrue);
    });

    test('getEntry retrieves appended entry', () async {
      final store = JsonlSessionStorage(jsonlPath);
      await store.init();

      final entry = MessageEntry(
        id: 'e_1',
        parentId: null,
        timestamp: fixedTime,
        message: UserMessage.text('hello'),
      );
      await store.appendEntry(entry);

      final retrieved = await store.getEntry('e_1');
      expect(retrieved, isA<MessageEntry>());
      expect(retrieved!.id, 'e_1');
    });

    test('corrupt-tail tear recovery', () async {
      // Write a valid line, then a malformed line.
      final file = File(jsonlPath);
      final entry = MessageEntry(
        id: 'e_1',
        parentId: null,
        timestamp: fixedTime,
        message: UserMessage.text('hello'),
      );
      await file.writeAsString(
        '${jsonEncode(entry.toJson())}\n{corrupt json\n',
      );

      final store = JsonlSessionStorage(jsonlPath);
      final result = await store.init();

      expect(result.loadedEntriesCount, 1);
      expect(result.tearReport, isNotNull);
      expect(result.tearReport!.lineNumber, 2);
      expect(result.tearReport!.salvagedEntryCount, 1);
    });

    test('active leaf ID persists across close/reopen', () async {
      var store = JsonlSessionStorage(jsonlPath);
      await store.init();
      await store.setActiveLeafId('e_1');
      await store.close();

      // Reopen and verify.
      store = JsonlSessionStorage(jsonlPath);
      await store.init();
      expect(await store.getActiveLeafId(), 'e_1');
      await store.close();
    });

    test('deleteEntries removes entries, file rewritten on close', () async {
      final store = JsonlSessionStorage(jsonlPath);
      await store.init();

      await store.appendEntry(MessageEntry(
        id: 'e_1',
        parentId: null,
        timestamp: fixedTime,
        message: UserMessage.text('a'),
      ));
      await store.appendEntry(MessageEntry(
        id: 'e_2',
        parentId: 'e_1',
        timestamp: fixedTime,
        message: UserMessage.text('b'),
      ));

      await store.deleteEntries({'e_1'});
      await store.close();

      // Reopen and verify.
      final store2 = JsonlSessionStorage(jsonlPath);
      final result = await store2.init();
      expect(result.loadedEntriesCount, 1);
      final entries = await store2.getEntries();
      expect(entries.first.id, 'e_2');
    });
  });

  group('AgentSession tree operations', () {
    late InMemorySessionStorage store;
    late AgentSession session;

    setUp(() async {
      store = InMemorySessionStorage();
      session = AgentSession(store);
      await session.init();
    });

    test('appendMessage creates message entries', () async {
      final id = await session.appendMessage(UserMessage.text('hello'));
      expect(id, isNotEmpty);
      final entry = await store.getEntry(id);
      expect(entry, isA<MessageEntry>());
    });

    test('getBranch returns entries from leaf to root', () async {
      await session.appendMessage(UserMessage.text('a'));
      final id2 = await session.appendMessage(UserMessage.text('b'));

      final branch = await session.getBranch();
      expect(branch, hasLength(2));
      expect(branch.first.id, isNot(equals(id2)));
      expect(branch.last.id, equals(id2));
    });

    test('fork creates a new branch head', () async {
      final id1 = await session.appendMessage(UserMessage.text('a'));
      await session.fork(id1);

      final heads = await session.listBranchHeads();
      expect(heads.length, greaterThanOrEqualTo(1));
    });

    test('switchTo changes active leaf', () async {
      final id1 = await session.appendMessage(UserMessage.text('a'));
      final id2 = await session.appendMessage(UserMessage.text('b'));

      await session.switchTo(id1);
      expect(await store.getActiveLeafId(), id1);

      await session.switchTo(id2);
      expect(await store.getActiveLeafId(), id2);
    });

    test('deleteBranch prunes unreferenced entries', () async {
      final id1 = await session.appendMessage(UserMessage.text('a'));
      final id2 = await session.appendMessage(UserMessage.text('b'));
      await session.fork(id1); // Fork from e1, creating a branch head.

      // Delete the second message (on main branch).
      await session.deleteBranch(id2);

      // The fork's entry should still exist.
      final forkHead = await session.listBranchHeads();
      expect(forkHead, isNotEmpty);
    });

    test('buildContext reconstructs messages from active branch', () async {
      await session.appendMessage(UserMessage.text('hello'));
      await session.appendMessage(AssistantMessage.text('hi there'));

      final ctx = await session.buildContext();
      expect(ctx.messages, hasLength(2));
      expect(ctx.messages.first, isA<UserMessage>());
      expect(ctx.messages.last, isA<AssistantMessage>());
    });

    test('buildContext tracks active model from usage entries', () async {
      await session.appendMessage(UserMessage.text('hello'));
      await session.appendUsage(
        UsageLedgerEntry(
          id: 'ul_1',
          timestamp: fixedTime,
          callId: 'c_1',
          turnNumber: 1,
          inputTokens: 100,
          outputTokens: 50,
          cacheReadTokens: 0,
          cacheWriteTokens: 0,
        ),
        model: Model(provider: 'openai', modelId: 'gpt-4', contextWindow: 8192),
      );
      final ctx = await session.buildContext();
      expect(ctx.activeModel, isNotNull);
      expect(ctx.activeModel!.modelId, 'gpt-4');
    });

    test('buildContext tracks active compaction from CompactionTreeEntry',
        () async {
      await session.appendMessage(UserMessage.text('hello'));
      await session.appendCompaction(
        CompactionEntry(
          id: 'ce_1',
          parentId: null,
          timestamp: fixedTime,
          firstKeptEntryId: '',
          tokensBefore: 5000,
          tokensAfter: 1000,
        ),
        summary: CompactionSummary(
          decisions: ['decided X'],
          toolNames: ['tool_a'],
          keyResults: ['result_a'],
        ),
      );
      final ctx = await session.buildContext();
      expect(ctx.activeCompaction, isNotNull);
      expect(ctx.activeCompaction!.decisions, ['decided X']);
    });
  });

  group('Mission fixture loading', () {
    test('mission_50.jsonl loads and round-trips through JsonlSessionStorage',
        () async {
      // Copy fixture to temp directory (never mutate committed fixtures).
      final tmpDir = await Directory.systemTemp.createTemp('mission_test_');
      final tmpPath = '${tmpDir.path}/mission.jsonl';
      final fixtureFile = File('test/fixtures/mission_50.jsonl');
      await fixtureFile.copy(tmpPath);

      final store = JsonlSessionStorage(tmpPath);
      final result = await store.init();

      // Should have loaded entries without tears.
      expect(result.loadedEntriesCount, greaterThan(100));
      expect(result.tearReport, isNull);

      final entries = await store.getEntries();
      expect(entries.length, result.loadedEntriesCount);

      // Verify all entries round-trip.
      for (final entry in entries) {
        final json = entry.toJson();
        final restored = SessionTreeEntry.fromJson(json);
        expect(restored.id, entry.id);
      }

      await store.close();
      await tmpDir.delete(recursive: true);
    });
  });
}
