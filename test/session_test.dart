// Acceptance tests for US2 (branching session tree, quickstart Scenario 2):
// fork shares ancestry and diverges (AC1), switchTo isolates branches with
// no sibling leakage (AC2, invariant I3), close/reopen resumes from the
// persisted leaf with a byte-identical context (AC3, invariant I4), and
// deleteBranch prunes only leaf-only entries, retaining shared ancestry
// (research R8). Runs against all three stores.
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

/// Runs the branch-management contract against a store factory.
void runSessionSuite(
  String label,
  Future<Object> Function() createBacking,
  Future<SessionStorage> Function(Object backing) openStore,
) {
  group('AgentSession branch management ($label)', () {
    late Object backing;
    late SessionStorage storage;
    late AgentSession session;

    setUp(() async {
      backing = await createBacking();
      storage = await openStore(backing);
      session = AgentSession(storage);
    });

    Future<String> append(String text) =>
        session.appendMessage(UserMessage.text(text));

    List<String> texts(SessionContext ctx) => [
          for (final m in ctx.messages)
            (m as UserMessage).content.cast<TextBlock>().single.text,
        ];

    test('appends build a linear branch and reconstruct context', () async {
      final id1 = await append('a');
      final id2 = await append('b');
      final id3 = await append('c');
      expect(texts(await session.buildContext()), ['a', 'b', 'c']);
      final branch = await session.getBranch();
      expect(branch.map((e) => e.id).toList(), [id3, id2, id1],
          reason: 'getBranch returns leaf -> root (ported semantics)');
    });

    test('AC1: fork shares ancestry up to N and diverges from N+1', () async {
      final id1 = await append('a');
      final id2 = await append('b');
      final id3 = await append('c');
      final preFork = await session.buildContext();

      final forkLeaf = await session.fork(id2);
      expect(forkLeaf, id2, reason: 'fork returns the new branch leaf');
      final id4 = await append('d');
      final id5 = await append('e');

      // Shared ancestry: id1, id2 in both branches.
      final forkedBranch = await session.getBranch();
      expect(forkedBranch.map((e) => e.id).toList(), [id5, id4, id2, id1]);
      final all = await session.getEntries();
      expect(all.map((e) => e.id).toList(), containsAll([id3, id4, id5]));

      // The original branch reconstructs the pre-fork conversation exactly.
      await session.switchTo(id3);
      expect(await session.buildContext(), equals(preFork),
          reason: 'original branch context identical to pre-fork history');
    });

    test('AC2: switchTo between diverged branches leaks no siblings',
        () async {
      await append('a');
      final id2 = await append('b');
      final id3 = await append('c');
      await session.fork(id2);
      final id4 = await append('d');
      final id5 = await append('e');

      await session.switchTo(id3);
      expect(texts(await session.buildContext()), ['a', 'b', 'c']);

      await session.switchTo(id5);
      expect(texts(await session.buildContext()), ['a', 'b', 'd', 'e'],
          reason: 'fork branch shows only its own conversation');
    });

    test('deleteBranch prunes leaf-only entries and retains shared ancestry',
        () async {
      final id1 = await append('a');
      final id2 = await append('b');
      final id3 = await append('c'); // original branch leaf
      await session.fork(id2);
      final id4 = await append('d');
      final id5 = await append('e');

      final pruned = await session.deleteBranch(id5);
      expect(pruned, 2, reason: 'only leaf-only entries d and e pruned');
      expect(await session.getEntry(id4), isNull);
      expect(await session.getEntry(id5), isNull);
      expect(await session.getEntry(id1), isNotNull);
      expect(await session.getEntry(id2), isNotNull,
          reason: 'shared ancestry retained');
      expect(await session.getEntry(id3), isNotNull,
          reason: 'sibling branch ancestry untouched');

      // The sibling branch still reconstructs correctly.
      await session.switchTo(id3);
      expect(texts(await session.buildContext()), ['a', 'b', 'c']);
    });

    test('deleteBranch of the active leaf moves the leaf to the retained '
        'ancestor', () async {
      final id1 = await append('a');
      final id2 = await append('b');
      await append('c'); // sibling leaf
      await session.fork(id2);
      await append('d');
      final id5 = await append('e');

      await session.deleteBranch(id5);
      expect(await storage.getLeafId(), id2,
          reason: 'leaf moves to the entry where pruning stopped');
      expect(texts(await session.buildContext()), ['a', 'b'],
          reason: 'session remains usable from the retained ancestor');
    });

    test('deleteBranch of a non-leaf returns 0 and prunes nothing', () async {
      final id1 = await append('a');
      final id2 = await append('b');
      await append('c');
      expect(await session.deleteBranch(id2), 0);
      expect(await session.getEntry(id2), isNotNull);
      expect(await session.getEntry(id1), isNotNull);
    });

    test('deleteBranch of an unknown leaf throws SessionTreeException',
        () async {
      await append('a');
      expect(() => session.deleteBranch('nope'), throwsA(isA<SessionTreeException>()));
    });

    test('fork of an unknown entry throws SessionTreeException', () async {
      await append('a');
      expect(() => session.fork('nope'), throwsA(isA<SessionTreeException>()));
    });

    test('switchTo of an unknown entry throws SessionTreeException', () async {
      await append('a');
      expect(() => session.switchTo('nope'), throwsA(isA<SessionTreeException>()));
    });

    test('appendTurn rejects messageEntryIds off the active branch',
        () async {
      final id1 = await append('a');
      final id2 = await append('b');
      final id3 = await append('c');
      await session.fork(id2);
      await append('d'); // active branch: a, b, d

      final t = TurnRecord(
        id: newEntryId(),
        parentId: '',
        timestamp: DateTime.now(),
        turnNumber: 1,
        messageEntryIds: [id1, id3], // id3 is on the sibling branch
        startedAt: DateTime.now().subtract(const Duration(seconds: 1)),
        endedAt: DateTime.now(),
        durationMs: 10,
      );
      expect(() => session.appendTurn(t),
          throwsA(isA<SessionTreeException>()));
    });

    test('appendTurn accepts same-branch messageEntryIds', () async {
      final id1 = await append('a');
      final id2 = await append('b');
      final id3 = await append('c');
      final turn = TurnRecord(
        id: newEntryId(),
        parentId: '',
        timestamp: DateTime.now(),
        turnNumber: 1,
        messageEntryIds: [id1, id2, id3],
        startedAt: DateTime.now().subtract(const Duration(seconds: 1)),
        endedAt: DateTime.now(),
        durationMs: 10,
      );
      final turnId = await session.appendTurn(turn);
      expect(turnId, isNotEmpty);
      expect(await session.getEntry(turnId), isA<TurnRecord>());
    });

    test('appendCompaction rejects an entry not parented at the leaf',
        () async {
      await append('a');
      await append('b');
      final entry = CompactionEntry(
        id: newEntryId(),
        parentId: 'bogus-parent',
        timestamp: DateTime.now(),
        summary: const CompactionSummary(decisions: ['x']),
        firstKeptEntryId: 'a',
        tokensBefore: 10,
      );
      expect(() => session.appendCompaction(entry),
          throwsA(isA<SessionTreeException>()));
    });

    test('appendCompaction lands on the active branch only', () async {
      await append('a');
      final id2 = await append('b');
      await session.fork(id2);
      final id4 = await append('d');
      final entry = CompactionEntry(
        id: newEntryId(),
        parentId: id4,
        timestamp: DateTime.now(),
        summary: const CompactionSummary(decisions: ['compact']),
        firstKeptEntryId: id4,
        tokensBefore: 99,
      );
      final compactionId = await session.appendCompaction(entry);
      expect(compactionId, entry.id);
      expect(await storage.getLeafId(), compactionId);
      // Sibling branch unaffected.
      await session.switchTo(id2);
      // id2 is on the sibling path; compaction entry is not reachable from it.
      final siblingBranch = await session.getBranch();
      expect(siblingBranch.map((e) => e.id), isNot(contains(compactionId)));
    });

    test('appendUsage and appendToolInvocation land on the branch', () async {
      final id1 = await append('a');
      final usage = UsageLedgerEntry(
        id: newEntryId(),
        parentId: id1,
        timestamp: DateTime.now(),
        callId: 'c1',
        turnNumber: 1,
        model: const Model(
            provider: 'openai', modelId: 'gpt-4o', contextWindow: 128000),
        inputTokens: 5,
        outputTokens: 2,
      );
      final invocation = ToolInvocationRecord(
        id: newEntryId(),
        parentId: usage.id,
        timestamp: DateTime.now(),
        toolCallId: 'tc-1',
        toolName: 'search',
        arguments: const {'q': 'x'},
        durationMs: 3,
      );
      await session.appendUsage(usage);
      await session.appendToolInvocation(invocation);
      final entries = await session.getEntries();
      expect(entries.map((e) => e.id), containsAll([usage.id, invocation.id]));
      // Context is unchanged by non-message entries.
      expect(texts(await session.buildContext()), ['a']);
    });

    test('thinking/model changes update the reconstructed context', () async {
      await append('a');
      await session.appendThinkingLevelChange(ThinkingLevel.high);
      await session.appendModelChange('anthropic', 'claude-sonnet-4-20250514');
      await append('b');
      final ctx = await session.buildContext();
      expect(ctx.thinkingLevel, ThinkingLevel.high);
      expect(ctx.model.provider, 'anthropic');
      expect(ctx.model.modelId, 'claude-sonnet-4-20250514');
      expect(texts(ctx), ['a', 'b']);
    });

    test('moveTo switches branches and records an optional summary', () async {
      await append('a');
      final id2 = await append('b');
      final id3 = await append('c');
      await session.moveTo(id2, summary: 'branch note');
      final branch = await session.getBranch();
      expect(branch.first, isA<BranchSummaryEntry>());
      expect((branch.first as BranchSummaryEntry).summary, 'branch note');
      expect(await storage.getLeafId(), branch.first.id);

      await session.moveTo(id3);
      expect(texts(await session.buildContext()), ['a', 'b', 'c']);
    });

    test('listBranchHeads returns leaves and labeled entries', () async {
      await append('a');
      final id2 = await append('b');
      final id3 = await append('c');
      await session.fork(id2);
      await append('d');
      final id5 = await append('e');

      // Heads before labeling: true leaves id3 and id5.
      var heads = await session.listBranchHeads();
      expect(heads.toSet(), {id3, id5});

      // Name id2 (the fork point) while standing on it: the label entry
      // parents at the current leaf, so standing on id2 keeps id3/id5
      // leaves and id2 becomes a named branch head.
      await session.switchTo(id2);
      await session.appendLabel(id2, label: 'main');
      heads = await session.listBranchHeads();
      expect(heads.toSet(), {id3, id5, id2},
          reason: 'labeled non-leaf is a named branch head');
    });

    test('labels and custom entries append as entries', () async {
      final id1 = await append('a');
      await session.appendLabel(id1, label: 'root');
      await session.appendCustomEntry('meta', data: const {'k': 'v'});
      final entries = await session.getEntries();
      expect(entries.whereType<LabelEntry>(), hasLength(1));
      expect(entries.whereType<CustomEntry>(), hasLength(1));
    });

    test('getBranch fromId reconstructs a specific ancestry', () async {
      final id1 = await append('a');
      final id2 = await append('b');
      await append('c');
      final branch = await session.getBranch(fromId: id2);
      expect(branch.map((e) => e.id).toList(), [id2, id1]);
    });
  });
}

/// Runs the restart contract (close/reopen resumes from the persisted leaf).
void runRestartSuite(
  String label,
  Future<Object> Function() createBacking,
  Future<SessionStorage> Function(Object backing) openStore,
) {
  group('AgentSession restart ($label)', () {
    test('AC3: reopen resumes with a byte-identical context', () async {
      final backing = await createBacking();

      final storage1 = await openStore(backing);
      final session1 = AgentSession(storage1);
      await session1.appendMessage(UserMessage.text('a'));
      final id2 = await session1.appendMessage(UserMessage.text('b'));
      final id3 = await session1.appendMessage(UserMessage.text('c'));
      await session1.fork(id2);
      await session1.appendMessage(UserMessage.text('d'));
      await session1.appendMessage(UserMessage.text('e'));
      // End on the ORIGINAL branch so the persisted leaf is id3 (c).
      await session1.switchTo(id3);
      final preRestart = await session1.buildContext();
      await storage1.close();

      final storage2 = await openStore(backing);
      final session2 = AgentSession(storage2);
      final postRestart = await session2.buildContext();
      expect(postRestart, equals(preRestart),
          reason: 'context after restart byte-identical to pre-restart');
      expect(await storage2.getLeafId(), id3,
          reason: 'resumed from the persisted leaf, not derived');
      expect(
        (postRestart.messages as List<dynamic>)
            .map((m) => ((m as UserMessage).content.single as TextBlock).text)
            .toList(),
        ['a', 'b', 'c'],
      );
    });
  });
}

void main() {
  final tmpRoot = <Directory>[];
  tearDownAll(() async {
    for (final d in tmpRoot) {
      try {
        await d.delete(recursive: true);
      } on FileSystemException {
        // Ignore cleanup failures.
      }
    }
  });
  Future<Directory> newTmpDir(String prefix) async {
    final d = await Directory.systemTemp.createTemp('zuraffa_$prefix');
    tmpRoot.add(d);
    return d;
  }

  var boxCounter = 0;

  runSessionSuite(
    'InMemory',
    () async => const Object(),
    (_) async => InMemorySessionStorage(),
  );

  runSessionSuite(
    'Jsonl',
    () async => File('${(await newTmpDir('sess_jsonl_')).path}/s.jsonl').path,
    (backing) async => JsonlSessionStorage(backing as String),
  );

  runSessionSuite(
    'Hive',
    () async => (
        boxName: 'sess_box_${boxCounter++}',
        hivePath: (await newTmpDir('sess_hive_')).path),
    (backing) async {
      final (boxName: name, hivePath: path) =
          backing as ({String boxName, String hivePath});
      return HiveSessionStorage(name, hivePath: path);
    },
  );

  runRestartSuite(
    'Jsonl',
    () async => File('${(await newTmpDir('restart_jsonl_')).path}/s.jsonl').path,
    (backing) async => JsonlSessionStorage(backing as String),
  );

  runRestartSuite(
    'Hive',
    () async => (
        boxName: 'restart_box_${boxCounter++}',
        hivePath: (await newTmpDir('restart_hive_')).path),
    (backing) async {
      final (boxName: name, hivePath: path) =
          backing as ({String boxName, String hivePath});
      return HiveSessionStorage(name, hivePath: path);
    },
  );
}
