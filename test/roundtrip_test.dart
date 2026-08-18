// Acceptance test for US1 (typed round-trip, quickstart Scenario 1, spec AC1).
//
// Builds a deterministic 3-turn mission (user -> assistant w/ thinking +
// tool calls -> tool results, closed by TurnRecord, ToolInvocationRecord per
// call, UsageLedgerEntry per LLM call), persists it through the JSONL and
// Hive stores, closes and reopens each, and asserts:
//   - every entry is retrievable by ID as its concrete typed subclass
//     (no `Map<String, dynamic>` escapes in the public API);
//   - UsageLedger totals match the fixture's known token counts;
//   - Hive and JSONL produce identical entry sequences (cross-store
//     equivalence).
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

/// Deterministic 3-turn mission with explicit entry IDs.
///
/// Entry ids are `e001..e0NN` so `loadEntries` (insertion order) returns the
/// same sequence as append order.
class Mission {
  Mission({
    required this.entries,
    required this.leafId,
    required this.totalInputTokens,
    required this.totalOutputTokens,
    required this.usageEntries,
  });

  final List<SessionTreeEntry> entries;
  final String leafId;
  final int totalInputTokens;
  final int totalOutputTokens;
  final List<UsageLedgerEntry> usageEntries;

  SessionTreeEntry? operator [](String id) {
    for (final e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }
}

/// Builds the deterministic mission fixture (quickstart Scenario 1).
Mission buildMission() {
  final entries = <SessionTreeEntry>[];
  final usageEntries = <UsageLedgerEntry>[];
  final byId = <String, SessionTreeEntry>{};
  var n = 0;
  DateTime ts(int i) => DateTime.utc(2026, 1, 1).add(Duration(minutes: i));

  void add(SessionTreeEntry e) {
    entries.add(e);
    byId[e.id] = e;
  }

  String nextId() => 'e${(++n).toString().padLeft(3, '0')}';

  const model = Model(
    provider: 'anthropic',
    modelId: 'claude-sonnet-4-20250514',
    contextWindow: 200000,
  );

  // --- Turn 1: 2 tool calls -------------------------------------------------
  final user1 = MessageEntry(
    id: nextId(),
    parentId: '',
    timestamp: ts(n),
    role: 'user',
    message: UserMessage.text('Plan the mission and call tools.'),
  );
  add(user1);
  final assistant1 = MessageEntry(
    id: nextId(),
    parentId: user1.id,
    timestamp: ts(n),
    role: 'assistant',
    message: AssistantMessage(
      content: [
        const ThinkingBlock('I will break this into steps.'),
        const ToolCallBlock(id: 'tc-1', name: 'search', arguments: {
          'q': 'alpha',
          'limit': 5,
        }),
        const ToolCallBlock(
            id: 'tc-2', name: 'read', arguments: {'path': 'doc.md'}),
      ],
      stopReason: StopReason.toolUse,
      usage: const Usage(inputTokens: 800, outputTokens: 300),
    ),
  );
  add(assistant1);
  final result1a = MessageEntry(
    id: nextId(),
    parentId: assistant1.id,
    timestamp: ts(n),
    role: 'toolResult',
    message: ToolResultMessage.text(
        toolCallId: 'tc-1', toolName: 'search', text: 'alpha results'),
  );
  add(result1a);
  final result1b = MessageEntry(
    id: nextId(),
    parentId: result1a.id,
    timestamp: ts(n),
    role: 'toolResult',
    message: ToolResultMessage.text(
        toolCallId: 'tc-2',
        toolName: 'read',
        text: 'doc content',
        isError: true),
  );
  add(result1b);
  add(ToolInvocationRecord(
    id: nextId(),
    parentId: result1b.id,
    timestamp: ts(n),
    toolCallId: 'tc-1',
    toolName: 'search',
    arguments: const {'q': 'alpha', 'limit': 5},
    resultEntryId: result1a.id,
    isError: false,
    durationMs: 240,
    artifactRefs: const [ArtifactRef(kind: 'tool-output', id: 'out-1')],
  ));
  add(ToolInvocationRecord(
    id: nextId(),
    parentId: byId[entries.last.id]!.id,
    timestamp: ts(n),
    toolCallId: 'tc-2',
    toolName: 'read',
    arguments: const {'path': 'doc.md'},
    resultEntryId: result1b.id,
    isError: true,
    durationMs: 90,
    artifactRefs: const [],
  ));
  add(TurnRecord(
    id: nextId(),
    parentId: byId[entries.last.id]!.id,
    timestamp: ts(n),
    turnNumber: 1,
    messageEntryIds: [user1.id, assistant1.id, result1a.id, result1b.id],
    stopReason: StopReason.toolUse,
    startedAt: ts(n - 5),
    endedAt: ts(n),
    durationMs: 812,
  ));
  final usage1 = UsageLedgerEntry(
    id: nextId(),
    parentId: byId[entries.last.id]!.id,
    timestamp: ts(n),
    callId: 'call-1',
    turnNumber: 1,
    model: model,
    inputTokens: 800,
    outputTokens: 300,
    cacheReadInputTokens: 200,
  );
  add(usage1);
  usageEntries.add(usage1);

  // --- Turn 2: 3 tool calls -------------------------------------------------
  final user2 = MessageEntry(
    id: nextId(),
    parentId: byId[entries.last.id]!.id,
    timestamp: ts(n),
    role: 'user',
    message: UserMessage.text('Continue with the next phase.'),
  );
  add(user2);
  final assistant2 = MessageEntry(
    id: nextId(),
    parentId: user2.id,
    timestamp: ts(n),
    role: 'assistant',
    message: AssistantMessage(
      content: [
        const ThinkingBlock('Next phase requires three lookups.'),
        const ToolCallBlock(id: 'tc-3', name: 'search', arguments: {'q': 'beta'}),
        const ToolCallBlock(
            id: 'tc-4', name: 'bash', arguments: {'cmd': 'ls -la'}),
        const ToolCallBlock(
            id: 'tc-5', name: 'read', arguments: {'path': 'notes.md'}),
      ],
      stopReason: StopReason.toolUse,
      usage: const Usage(inputTokens: 1500, outputTokens: 450),
    ),
  );
  add(assistant2);
  final turn2Results = <String>[];
  for (final (callId, name, text) in [
    ('tc-3', 'search', 'beta results'),
    ('tc-4', 'bash', 'file listing'),
    ('tc-5', 'read', 'notes content'),
  ]) {
    final r = MessageEntry(
      id: nextId(),
      parentId: byId[entries.last.id]!.id,
      timestamp: ts(n),
      role: 'toolResult',
      message:
          ToolResultMessage.text(toolCallId: callId, toolName: name, text: text),
    );
    add(r);
    turn2Results.add(r.id);
  }
  for (final (i, (callId, name, args)) in [
    ('tc-3', 'search', {'q': 'beta'}),
    ('tc-4', 'bash', {'cmd': 'ls -la'}),
    ('tc-5', 'read', {'path': 'notes.md'}),
  ].indexed) {
    add(ToolInvocationRecord(
      id: nextId(),
      parentId: byId[entries.last.id]!.id,
      timestamp: ts(n),
      toolCallId: callId,
      toolName: name,
      arguments: args,
      resultEntryId: turn2Results[i],
      isError: false,
      durationMs: 150,
      artifactRefs: const [ArtifactRef(kind: 'tool-output', id: 'out-2')],
    ));
  }
  add(TurnRecord(
    id: nextId(),
    parentId: byId[entries.last.id]!.id,
    timestamp: ts(n),
    turnNumber: 2,
    messageEntryIds: [user2.id, assistant2.id, ...turn2Results],
    stopReason: StopReason.toolUse,
    startedAt: ts(n - 6),
    endedAt: ts(n),
    durationMs: 1230,
  ));
  final usage2 = UsageLedgerEntry(
    id: nextId(),
    parentId: byId[entries.last.id]!.id,
    timestamp: ts(n),
    callId: 'call-2',
    turnNumber: 2,
    model: model,
    inputTokens: 1500,
    outputTokens: 450,
  );
  add(usage2);
  usageEntries.add(usage2);

  // --- Turn 3: 1 tool call, ends naturally -----------------------------------
  final user3 = MessageEntry(
    id: nextId(),
    parentId: byId[entries.last.id]!.id,
    timestamp: ts(n),
    role: 'user',
    message: UserMessage.text('Wrap up with a final decision.'),
  );
  add(user3);
  final assistant3 = MessageEntry(
    id: nextId(),
    parentId: user3.id,
    timestamp: ts(n),
    role: 'assistant',
    message: AssistantMessage(
      content: [
        const ToolCallBlock(id: 'tc-6', name: 'search', arguments: {'q': 'gamma'}),
      ],
      stopReason: StopReason.toolUse,
      usage: const Usage(inputTokens: 900, outputTokens: 260),
    ),
  );
  add(assistant3);
  final result3 = MessageEntry(
    id: nextId(),
    parentId: assistant3.id,
    timestamp: ts(n),
    role: 'toolResult',
    message: ToolResultMessage.text(
        toolCallId: 'tc-6', toolName: 'search', text: 'gamma results'),
  );
  add(result3);
  add(ToolInvocationRecord(
    id: nextId(),
    parentId: result3.id,
    timestamp: ts(n),
    toolCallId: 'tc-6',
    toolName: 'search',
    arguments: const {'q': 'gamma'},
    resultEntryId: result3.id,
    isError: false,
    durationMs: 200,
    artifactRefs: const [],
  ));
  final decision = MessageEntry(
    id: nextId(),
    parentId: byId[entries.last.id]!.id,
    timestamp: ts(n),
    role: 'assistant',
    message: AssistantMessage(
      content: [const TextBlock('Decision: adopt alpha strategy.')],
      stopReason: StopReason.endTurn,
    ),
  );
  add(decision);
  add(TurnRecord(
    id: nextId(),
    parentId: byId[entries.last.id]!.id,
    timestamp: ts(n),
    turnNumber: 3,
    messageEntryIds: [user3.id, assistant3.id, result3.id, decision.id],
    stopReason: StopReason.endTurn,
    startedAt: ts(n - 4),
    endedAt: ts(n),
    durationMs: 640,
  ));
  final usage3 = UsageLedgerEntry(
    id: nextId(),
    parentId: byId[entries.last.id]!.id,
    timestamp: ts(n),
    callId: 'call-3',
    turnNumber: 3,
    model: model,
    inputTokens: 900,
    outputTokens: 260,
  );
  add(usage3);
  usageEntries.add(usage3);

  return Mission(
    entries: entries,
    leafId: entries.last.id,
    totalInputTokens: 800 + 1500 + 900,
    totalOutputTokens: 300 + 450 + 260,
    usageEntries: usageEntries,
  );
}

/// Persists [mission] through [store], closes, reopens and reloads.
Future<List<SessionTreeEntry>> roundTrip(
  SessionStorage store,
  Mission mission,
) async {
  await store.init();
  for (final e in mission.entries) {
    await store.appendEntry(e);
  }
  await store.setLeafId(mission.leafId);
  await store.setMetadata(SessionInfo(
    id: 'mission-1',
    name: 'Round-trip mission',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1, 1),
    metadata: const {'author': 'test'},
  ));
  await store.close();

  // Reopen the same backing store.
  await store.init();
  final reloaded = await store.loadEntries();
  return reloaded;
}

void main() {
  late Mission mission;
  late Directory tmp;

  setUp(() async {
    mission = buildMission();
    tmp = await Directory.systemTemp.createTemp('zuraffa_roundtrip_');
  });

  tearDown(() async {
    try {
      await tmp.delete(recursive: true);
    } on FileSystemException {
      // Ignore cleanup failures.
    }
  });

  test('US1 AC1: typed round-trip via JsonlSessionStorage', () async {
    final file = File('${tmp.path}/mission.jsonl');
    final store = JsonlSessionStorage(file.path);

    final reloaded = await roundTrip(store, mission);

    // Every entry reloaded as its concrete typed subclass, retrievable by id.
    expect(reloaded.length, mission.entries.length);
    for (final e in mission.entries) {
      final found = await store.findEntry(e.id);
      expect(found, isNotNull, reason: 'entry ${e.id} retrievable by id');
      expect(found.runtimeType, e.runtimeType,
          reason: 'entry ${e.id} reloaded as its concrete type');
      expect(found, equals(e), reason: 'entry ${e.id} payload equality');
    }

    // Cross-store equivalence with the Hive store.
    final hiveDir = Directory('${tmp.path}/hive');
    final hiveStore = HiveSessionStorage('mission_box',
        hivePath: hiveDir.path);
    final hiveReloaded = await roundTrip(hiveStore, mission);
    expect(hiveReloaded.length, reloaded.length);
    for (var i = 0; i < reloaded.length; i++) {
      expect(hiveReloaded[i].id, reloaded[i].id,
          reason: 'sequence $i identical across stores');
      expect(hiveReloaded[i], equals(reloaded[i]),
          reason: 'entry $i equal across stores');
    }
  });

  test('US1 AC1: no Map<String, dynamic> escapes in the round-trip',
      () async {
    final file = File('${tmp.path}/mission.jsonl');
    final store = JsonlSessionStorage(file.path);
    final reloaded = await roundTrip(store, mission);

    for (final e in reloaded) {
      expect(e, isA<SessionTreeEntry>());
      switch (e) {
        case MessageEntry():
          expect(e.message, isA<AgentMessage>());
        case TurnRecord():
          expect(e.messageEntryIds, isNotEmpty);
        case ToolInvocationRecord():
          expect(e.toolCallId, isNotEmpty);
        case UsageLedgerEntry():
          expect(e.inputTokens, greaterThanOrEqualTo(0));
        case _:
          break;
      }
    }
  });

  test('US1 AC1: ledger totals match the fixture known counts', () async {
    final ledger = UsageLedger.fromEntries(mission.usageEntries);
    expect(ledger.totalInputTokens, mission.totalInputTokens);
    expect(ledger.totalOutputTokens, mission.totalOutputTokens);
    expect(ledger.byTurn().length, 3);
    expect(ledger.byModel().values.fold<int>(0, (a, b) => a + b),
        mission.totalInputTokens + mission.totalOutputTokens);
  });

  test('US1 AC1: leaf and metadata persist across restart', () async {
    final file = File('${tmp.path}/mission.jsonl');
    final store = JsonlSessionStorage(file.path);
    await roundTrip(store, mission);
    expect(await store.getLeafId(), mission.leafId);
    final meta = await store.getMetadata();
    expect(meta.id, 'mission-1');
    expect(meta.name, 'Round-trip mission');
    expect(meta.metadata['author'], 'test');
  });
}
