// Unit tests for the hand-written Hive TypeAdapters (research R4): every
// entity/message/block type round-trips through Hive binary with typed
// payload equality, and adapter type IDs are deterministic.
library;

import 'dart:io';

import 'package:hive_ce/hive_ce.dart' as hive;
import 'package:test/test.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

/// Builds one entry of every session-tree type (same set as the shared
/// contract suite, see session_storage_test.dart).
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
      cacheReadInputTokens: 2,
    ),
  ];
}

void main() {
  late Directory dir;
  late hive.Box<Object> box;
  var boxCounter = 0;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('zuraffa_hive_adapter_');
    registerZuraffaAdapters();
    box = await hive.Hive.openBox<Object>('adapter_box_${boxCounter++}',
        path: dir.path);
  });

  tearDown(() async {
    await box.close();
    try {
      await dir.delete(recursive: true);
    } on FileSystemException {
      // Ignore cleanup failures.
    }
  });

  test('every entity type round-trips with typed payload equality', () async {
    for (final e in allEntryTypes()) {
      await box.put(e.id, e);
    }
    for (final e in allEntryTypes()) {
      final loaded = box.get(e.id);
      expect(loaded, isNotNull, reason: 'entry ${e.id} stored');
      expect(loaded.runtimeType, e.runtimeType,
          reason: 'entry ${e.id} reads back as its concrete type');
      expect(loaded, equals(e),
          reason: 'entry ${e.id} payload equality after Hive round-trip');
    }
  });

  test('multimodal messages with every block type round-trip', () async {
    final user = MessageEntry(
      id: 'm1',
      parentId: '',
      timestamp: DateTime.utc(2026, 4, 1),
      role: 'user',
      message: UserMessage(content: [
        const TextBlock('look at these'),
        const ImageBlock(base64Data: 'aGVsbG8=', mediaType: 'image/png'),
        const AudioBlock(
            base64Data: 'c291bmQ=', mediaType: 'audio/wav', transcript: 'hi'),
        const DocumentBlock(
            mediaType: 'application/pdf', base64Data: 'ZG9j', title: 'spec'),
      ]),
    );
    final assistant = MessageEntry(
      id: 'm2',
      parentId: 'm1',
      timestamp: DateTime.utc(2026, 4, 1, 1),
      role: 'assistant',
      message: AssistantMessage(
        content: [
          const ThinkingBlock('reasoning...'),
          const ToolCallBlock(id: 't1', name: 'bash', arguments: {'cmd': 'ls'}),
          const TextBlock('done'),
        ],
        stopReason: StopReason.toolUse,
        usage: const Usage(inputTokens: 9, outputTokens: 3, cacheReadInputTokens: 1),
      ),
    );

    for (final e in [user, assistant]) {
      await box.put(e.id, e);
    }
    for (final e in [user, assistant]) {
      final loaded = box.get(e.id);
      expect(loaded, equals(e));
      final msg = (loaded as MessageEntry).message;
      final blocks = msg is AssistantMessage ? msg.content : (msg as UserMessage).content;
      expect(blocks, hasLength(msg is AssistantMessage ? 3 : 4));
    }
  });

  test('compaction summary with artifact refs round-trips', () async {
    final entry = CompactionEntry(
      id: 'c1',
      parentId: 'root',
      timestamp: DateTime.utc(2026, 5, 1),
      summary: const CompactionSummary(
        decisions: ['keep a', 'keep b'],
        toolNames: ['bash', 'search'],
        keyResults: ['resolved x'],
        planState: 'phase 2',
        artifacts: [
          ArtifactRef(kind: 'tool-output', id: 'out-9'),
          ArtifactRef(kind: 'file', id: 'f-1'),
        ],
        prose: 'narrative',
      ),
      firstKeptEntryId: 'root',
      tokensBefore: 48000,
    );
    await box.put('compaction', entry);
    final loaded = box.get('compaction');
    expect(loaded, equals(entry));
    expect((loaded as CompactionEntry).summary.artifacts, hasLength(2));
    expect(loaded.summary.decisions, ['keep a', 'keep b']);
  });

  test('typed payload equality survives nested map values', () async {
    final entry = ToolInvocationRecord(
      id: 't1',
      parentId: 'p',
      timestamp: DateTime.utc(2026, 6, 1),
      toolCallId: 'tc-1',
      toolName: 'search',
      arguments: const {'filters': {'status': 'open', 'tags': ['a', 'b']}},
      resultEntryId: 'r1',
      isError: false,
      durationMs: 5,
      artifactRefs: const [ArtifactRef(kind: 'tool-output', id: 'o1')],
    );
    await box.put('t1', entry);
    final loaded = box.get('t1');
    expect(loaded, equals(entry));
    final args = (loaded as ToolInvocationRecord).arguments;
    expect(args['filters'], isA<Map>());
    expect((args['filters'] as Map)['tags'], isA<List>());
  });

  test('type IDs are deterministic and unique', () {
    final adapters = <hive.TypeAdapter<Object>>[
      UserMessageAdapter(),
      AssistantMessageAdapter(),
      ToolResultMessageAdapter(),
      CustomMessageAdapter(),
      TextBlockAdapter(),
      ImageBlockAdapter(),
      AudioBlockAdapter(),
      DocumentBlockAdapter(),
      ToolCallBlockAdapter(),
      ThinkingBlockAdapter(),
      MessageEntryAdapter(),
      ThinkingLevelChangeEntryAdapter(),
      ModelChangeEntryAdapter(),
      CompactionEntryAdapter(),
      BranchSummaryEntryAdapter(),
      LabelEntryAdapter(),
      CustomEntryAdapter(),
      TurnRecordAdapter(),
      ToolInvocationRecordAdapter(),
      UsageLedgerEntryAdapter(),
      ModelAdapter(),
      UsageAdapter(),
      CompactionSummaryAdapter(),
      ArtifactRefAdapter(),
      SessionInfoAdapter(),
    ];
    final ids = adapters.map((a) => a.typeId).toList();
    expect(ids.toSet(), hasLength(ids.length), reason: 'type IDs unique');

    // Deterministic constants (research R4): changing these breaks existing
    // Hive files, so they are pinned by test.
    expect(UserMessageAdapter().typeId, HiveTypeIds.userMessage);
    expect(AssistantMessageAdapter().typeId, HiveTypeIds.assistantMessage);
    expect(MessageEntryAdapter().typeId, HiveTypeIds.messageEntry);
    expect(TurnRecordAdapter().typeId, HiveTypeIds.turnRecord);
    expect(ToolInvocationRecordAdapter().typeId, HiveTypeIds.toolInvocationRecord);
    expect(UsageLedgerEntryAdapter().typeId, HiveTypeIds.usageLedgerEntry);
    expect(CompactionEntryAdapter().typeId, HiveTypeIds.compactionEntry);
    expect(SessionInfoAdapter().typeId, HiveTypeIds.sessionInfo);
  });
}
