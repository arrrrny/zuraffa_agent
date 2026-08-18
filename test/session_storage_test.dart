// Shared behavioral contract suite for every SessionStorage implementation
// (quickstart Scenario 1 edge cases, contracts/session-api.md).
//
// Runs the same within-session behavior tests against InMemory, JSONL, and
// Hive stores, plus close/reopen persistence tests for the file-backed
// stores and the corrupt-JSONL-tail tear edge case (research R7).
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

/// Builds one entry of every session-tree type with ids in append order.
List<SessionTreeEntry> allEntryTypes() {
  DateTime t(int i) => DateTime.utc(2026, 2, 1).add(Duration(minutes: i));
  return [
    MessageEntry(
      id: 'a1',
      parentId: '',
      timestamp: t(1),
      role: 'user',
      message: UserMessage.text('hello'),
    ),
    MessageEntry(
      id: 'a2',
      parentId: 'a1',
      timestamp: t(2),
      role: 'assistant',
      message: AssistantMessage(
        content: [TextBlock('hi'), ToolCallBlock(id: 'c1', name: 'tool', arguments: {'x': 1})],
        stopReason: StopReason.toolUse,
        usage: const Usage(inputTokens: 10, outputTokens: 5),
      ),
    ),
    MessageEntry(
      id: 'a3',
      parentId: 'a2',
      timestamp: t(3),
      role: 'toolResult',
      message: ToolResultMessage.text(toolCallId: 'c1', toolName: 'tool', text: 'ok'),
    ),
    MessageEntry(
      id: 'a4',
      parentId: 'a3',
      timestamp: t(4),
      role: 'custom',
      message: const CustomMessage(type: 'note', data: {'k': 'v'}, display: 'note'),
    ),
    ThinkingLevelChangeEntry(
        id: 'a5', parentId: 'a4', timestamp: t(5), level: ThinkingLevel.high),
    ModelChangeEntry(
        id: 'a6', parentId: 'a5', timestamp: t(6), provider: 'openai', modelId: 'gpt-4o'),
    CompactionEntry(
      id: 'a7',
      parentId: 'a6',
      timestamp: t(7),
      summary: const CompactionSummary(
        decisions: ['proceed'],
        toolNames: ['tool'],
        keyResults: ['ok'],
        planState: 'plan A',
        artifacts: [ArtifactRef(kind: 'tool-output', id: 'art-1')],
      ),
      firstKeptEntryId: 'a6',
      tokensBefore: 1000,
    ),
    BranchSummaryEntry(
        id: 'a8', parentId: 'a7', timestamp: t(8), summary: 'branch note'),
    LabelEntry(id: 'a9', parentId: 'a8', timestamp: t(9), targetId: 'a1', label: 'main'),
    CustomEntry(
        id: 'a10', parentId: 'a9', timestamp: t(10), customType: 'meta', data: {'x': 1}),
    TurnRecord(
      id: 'a11',
      parentId: 'a10',
      timestamp: t(11),
      turnNumber: 1,
      messageEntryIds: ['a1', 'a2', 'a3', 'a4'],
      stopReason: StopReason.toolUse,
      startedAt: t(1),
      endedAt: t(11),
      durationMs: 500,
    ),
    ToolInvocationRecord(
      id: 'a12',
      parentId: 'a11',
      timestamp: t(12),
      toolCallId: 'c1',
      toolName: 'tool',
      arguments: const {'x': 1},
      resultEntryId: 'a3',
      isError: false,
      durationMs: 30,
      artifactRefs: const [ArtifactRef(kind: 'tool-output', id: 'art-1')],
    ),
    UsageLedgerEntry(
      id: 'a13',
      parentId: 'a12',
      timestamp: t(13),
      callId: 'call-1',
      turnNumber: 1,
      model: const Model(provider: 'openai', modelId: 'gpt-4o', contextWindow: 128000),
      inputTokens: 10,
      outputTokens: 5,
    ),
  ];
}

final sampleMeta = SessionInfo(
  id: 's1',
  name: 'Contract suite',
  createdAt: DateTime.utc(2026, 2, 1),
  updatedAt: DateTime.utc(2026, 2, 1, 1),
  metadata: const {'k': 'v'},
);

/// Runs the within-session behavior contract against a fresh store.
void runContractSuite(String label, Future<SessionStorage> Function() create) {
  group('SessionStorage contract: $label', () {
    late SessionStorage store;

    setUp(() async {
      store = await create();
      await store.init();
    });

    test('round-trips every entry type with payload equality', () async {
      final entries = allEntryTypes();
      for (final e in entries) {
        await store.appendEntry(e);
      }
      final loaded = await store.loadEntries();
      expect(loaded, hasLength(entries.length));
      for (var i = 0; i < entries.length; i++) {
        expect(loaded[i], equals(entries[i]),
            reason: 'entry ${entries[i].id} round-trips as its concrete type');
        expect(loaded[i].runtimeType, entries[i].runtimeType);
      }
    });

    test('findEntry returns the entry by identity, null for unknown', () async {
      final entries = allEntryTypes();
      await store.appendEntry(entries[0]);
      await store.appendEntry(entries[1]);
      final found = await store.findEntry(entries[1].id);
      expect(found, equals(entries[1]));
      expect(found.runtimeType, entries[1].runtimeType);
      expect(await store.findEntry('nope'), isNull);
    });

    test('setLeafId/getLeafId round-trip', () async {
      expect(await store.getLeafId(), isNull);
      await store.setLeafId('leaf-1');
      expect(await store.getLeafId(), 'leaf-1');
      await store.setLeafId(null);
      expect(await store.getLeafId(), isNull);
    });

    test('setMetadata/getMetadata round-trip', () async {
      await store.setMetadata(sampleMeta);
      expect(await store.getMetadata(), equals(sampleMeta));
    });

    test('removeEntry removes only the targeted entry', () async {
      final entries = allEntryTypes();
      for (final e in entries) {
        await store.appendEntry(e);
      }
      await store.removeEntry(entries[5].id);
      final loaded = await store.loadEntries();
      expect(loaded, hasLength(entries.length - 1));
      expect(await store.findEntry(entries[5].id), isNull);
      expect(loaded.map((e) => e.id), isNot(contains(entries[5].id)));
      expect(loaded.first, equals(entries.first));
      expect(loaded.last, equals(entries.last));
    });

    test('loadEntries order matches append order (insertion order)',
        () async {
      final entries = allEntryTypes();
      for (final e in entries) {
        await store.appendEntry(e);
      }
      final loaded = await store.loadEntries();
      expect(loaded.map((e) => e.id).toList(),
          entries.map((e) => e.id).toList());
    });

    test('loadEntries returns a defensive copy', () async {
      await store.appendEntry(allEntryTypes()[0]);
      final loaded = await store.loadEntries();
      loaded.clear();
      expect(await store.loadEntries(), hasLength(1));
    });
  });
}

/// Runs the persistence contract (close + reopen with same backing).
///
/// [createBacking] returns an opaque handle for a persistent location
/// (created once); [createStore] builds a store over that same backing each
/// time it is called, simulating a process restart.
void runPersistenceSuite(
  String label,
  Future<Object> Function() createBacking,
  Future<SessionStorage> Function(Object backing) createStore,
) {
  group('SessionStorage persistence: $label', () {
    test('entries, leaf, and metadata survive close/reopen', () async {
      final backing = await createBacking();
      final store = await createStore(backing);
      await store.init();
      final entries = allEntryTypes();
      for (final e in entries) {
        await store.appendEntry(e);
      }
      await store.setLeafId('leaf-9');
      await store.setMetadata(sampleMeta);
      await store.close();

      final reopened = await createStore(backing);
      await reopened.init();
      final loaded = await reopened.loadEntries();
      expect(loaded, hasLength(entries.length));
      for (var i = 0; i < entries.length; i++) {
        expect(loaded[i], equals(entries[i]));
      }
      expect(await reopened.getLeafId(), 'leaf-9');
      expect(await reopened.getMetadata(), equals(sampleMeta));
      await reopened.close();
    });
  });
}

void main() {
  var boxCounter = 0;
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

  runContractSuite(
    'InMemory',
    () async => InMemorySessionStorage(),
  );

  runContractSuite(
    'Jsonl',
    () async =>
        JsonlSessionStorage(File('${(await newTmpDir('jsonl_')).path}/s.jsonl').path),
  );

  runContractSuite(
    'Hive',
    () async => HiveSessionStorage(
      'contract_box_${boxCounter++}',
      hivePath: (await newTmpDir('hive_')).path,
    ),
  );

  runPersistenceSuite(
    'Jsonl',
    () async => File('${(await newTmpDir('jsonl_persist_')).path}/s.jsonl').path,
    (backing) async => JsonlSessionStorage(backing as String),
  );

  runPersistenceSuite(
    'Hive',
    () async => (
        boxName: 'persist_box_${boxCounter++}',
        hivePath: (await newTmpDir('hive_persist_')).path),
    (backing) async {
      final (boxName: name, hivePath: path) =
          backing as ({String boxName, String hivePath});
      return HiveSessionStorage(name, hivePath: path);
    },
  );

  group('JsonlSessionStorage tear handling (research R7)', () {
    test('truncated tail loads the salvaged prefix and reports the tear',
        () async {
      final dir = await newTmpDir('jsonl_tear_');
      final path = File('${dir.path}/torn.jsonl').path;
      final good = allEntryTypes().take(3).toList();

      // Write a valid prefix through the production codec, then append an
      // undecodable tail line directly to the file.
      final writer = JsonlSessionStorage(path);
      await writer.init();
      for (final e in good) {
        await writer.appendEntry(e);
      }
      await writer.close();
      File(path).writeAsStringSync('{not json\n', mode: FileMode.append);

      final store = JsonlSessionStorage(path);
      final result = await store.init();
      expect(result.tears, hasLength(1));
      final tear = result.tears.single;
      expect(tear.lineNumber, good.length + 1,
          reason: 'first undecodable line reported');
      expect(tear.reason, isNotEmpty);
      expect(tear.salvagedEntryCount, good.length);

      final loaded = await store.loadEntries();
      expect(loaded, hasLength(good.length));
      for (var i = 0; i < good.length; i++) {
        expect(loaded[i], equals(good[i]));
      }
      expect(await store.getLeafId(), good.last.id,
          reason: 'leaf defaults to the last salvaged entry');
    });

    test('stops at the first bad line (later valid lines not loaded)',
        () async {
      final dir = await newTmpDir('jsonl_tear2_');
      final path = File('${dir.path}/torn2.jsonl').path;
      final good = allEntryTypes().take(2).toList();

      final writer = JsonlSessionStorage(path);
      await writer.init();
      await writer.appendEntry(good[0]);
      await writer.close();
      File(path).writeAsStringSync('{not json\n', mode: FileMode.append);

      // Reopen: tears at line 2; a subsequent append lands on line 3 but the
      // loader must stop at line 2 on the final reopen.
      final writer2 = JsonlSessionStorage(path);
      await writer2.init();
      await writer2.appendEntry(good[1]);
      await writer2.close();

      final store = JsonlSessionStorage(path);
      final result = await store.init();
      expect(result.tears, hasLength(1));
      expect(result.tears.single.lineNumber, 2);
      final loaded = await store.loadEntries();
      expect(loaded, hasLength(1));
      expect(loaded.single, equals(good[0]));
    });

    test('blank lines are skipped and do not tear', () async {
      final dir = await newTmpDir('jsonl_tear3_');
      final path = File('${dir.path}/clean.jsonl').path;
      final good = allEntryTypes().take(2).toList();

      final writer = JsonlSessionStorage(path);
      await writer.init();
      await writer.appendEntry(good[0]);
      await writer.close();
      File(path).writeAsStringSync('\n', mode: FileMode.append);

      final writer2 = JsonlSessionStorage(path);
      await writer2.init();
      await writer2.appendEntry(good[1]);
      await writer2.close();

      final store = JsonlSessionStorage(path);
      final result = await store.init();
      expect(result.isClean, isTrue);
      expect(await store.loadEntries(), hasLength(2));
    });

    test('missing file loads clean with no entries', () async {
      final dir = await newTmpDir('jsonl_tear4_');
      final store = JsonlSessionStorage('${dir.path}/absent.jsonl');
      final result = await store.init();
      expect(result.isClean, isTrue);
      expect(await store.loadEntries(), isEmpty);
    });
  });

  group('Performance (plan.md goals)', () {
    test('200-entry JSONL round-trip completes well under 1s', () async {
      final dir = await newTmpDir('jsonl_perf_');
      final store =
          JsonlSessionStorage(File('${dir.path}/perf.jsonl').path);
      await store.init();
      final watch = Stopwatch()..start();
      for (var i = 0; i < 200; i++) {
        await store.appendEntry(MessageEntry(
          id: 'p${i.toString().padLeft(3, '0')}',
          parentId: i == 0 ? '' : 'p${(i - 1).toString().padLeft(3, '0')}',
          timestamp: DateTime.utc(2026, 3, 1).add(Duration(milliseconds: i)),
          role: 'user',
          message: UserMessage.text('message number $i'),
        ));
      }
      await store.close();
      await store.init();
      final loaded = await store.loadEntries();
      watch.stop();
      expect(loaded, hasLength(200));
      expect(watch.elapsedMilliseconds, lessThan(2000),
          reason: 'append + reopen + load of 200 entries < 2s '
              '(measured ${watch.elapsedMilliseconds}ms)');
    });
  });
}
