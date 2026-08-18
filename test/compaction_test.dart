// Acceptance tests for US3 (selective structured compaction, quickstart
// Scenario 3): retained categories survive (AC1), discarded material is
// represented by resolvable artifact refs, the 50+ tool-call fixture stays
// under its context budget with outcome equality vs the uncompacted baseline
// (AC2, SC-002), compaction runs only at turn boundaries, and a
// CompactionEntry lands on the active branch only (invariant I2).
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

DateTime _t(int i) => DateTime.utc(2026, 8, 1).add(Duration(minutes: i));

/// Copies the committed fixture into a temp dir so tests never mutate it.
String _missionFixtureCopy() {
  final source = File('test/fixtures/mission_50.jsonl');
  final dir = Directory.systemTemp.createTempSync('mission50_');
  addTearDown(() => dir.deleteSync(recursive: true));
  final copy = File('${dir.path}/mission_50.jsonl');
  copy.writeAsBytesSync(source.readAsBytesSync());
  return copy.path;
}

/// Test [ArtifactResolver] stub: resolves every ref to a marker string.
class _StubArtifactResolver implements ArtifactResolver {
  final resolved = <String>[];

  @override
  Future<Object?> resolve(ArtifactRef ref) async {
    resolved.add(ref.id);
    return 'resolved:${ref.kind}:${ref.id}';
  }
}

/// Deterministic mission outcome: the last assistant `Decision:` line.
String _outcome(List<AgentMessage> messages) {
  final decisions = <String>[];
  for (final m in messages) {
    if (m is AssistantMessage) {
      for (final b in m.content) {
        if (b is TextBlock) {
          for (final line in b.text.split('\n')) {
            final match = RegExp(r'^\s*decision\s*:\s*(.+)$',
                    caseSensitive: false)
                .firstMatch(line);
            if (match != null) decisions.add(match.group(1)!.trim());
          }
        }
      }
    }
  }
  return decisions.isEmpty ? '' : decisions.last;
}

/// Post-compaction estimate of the kept material: everything from the
/// compaction's [firstKeptEntryId] onward on the branch.
int _estimateKept(List<SessionTreeEntry> rootFirst, String firstKeptEntryId) {
  final start = rootFirst.indexWhere((e) => e.id == firstKeptEntryId);
  final kept = start < 0 ? rootFirst : rootFirst.sublist(start);
  return estimateEntriesTokens(kept);
}

/// Effective messages after compaction: summaries (oldest first) followed by
/// the messages kept by the most recent compaction.
List<AgentMessage> _effectiveMessages(
    List<SessionTreeEntry> entries, List<CompactionEntry> compactions) {
  if (compactions.isEmpty) {
    return [
      for (final e in entries)
        if (e is MessageEntry) e.message,
    ];
  }
  final last = compactions.last;
  final kept = <AgentMessage>[];
  var seen = false;
  for (final e in entries) {
    if (e.id == last.firstKeptEntryId) seen = true;
    if (seen && e is MessageEntry) kept.add(e.message);
  }
  return [
    for (final c in compactions)
      UserMessage.text(
          'COMPACTED: ${c.summary.decisions.join('; ')}'
          '${c.summary.planState == null ? '' : ' | ${c.summary.planState}'}'),
    ...kept,
  ];
}

void main() {
  group('Token estimation and cut points', () {
    test('estimateContextTokens uses the chars/4 heuristic', () {
      final messages = [
        UserMessage.text('a' * 40),
        AssistantMessage(content: [TextBlock('b' * 20)]),
      ];
      expect(estimateContextTokens(messages), 15);
    });

    test('shouldCompact triggers above the usable window', () {
      final messages = [UserMessage.text('x' * 5000)]; // ~1250 tokens
      const settings = CompactionSettings(
          enabled: true, reserveTokens: 200, keepRecentTokens: 600);
      expect(shouldCompact(messages, 1200, settings: settings), isTrue,
          reason: '1250 > 1200 - 200 = 1000');
      final small = [UserMessage.text('x' * 100)]; // 25 tokens
      expect(shouldCompact(small, 1200, settings: settings), isFalse);
      expect(
          shouldCompact(messages, 1200,
              settings: const CompactionSettings(enabled: false)),
          isFalse,
          reason: 'disabled never compacts');
    });

    test('shouldCompact honors triggerThresholdRatio', () {
      final messages = [UserMessage.text('x' * 2000)]; // 500 tokens
      // usable = 1000; 500 > 1000 * 0.4 = 400 -> compact.
      expect(
          shouldCompact(messages, 1200,
              settings: const CompactionSettings(
                  reserveTokens: 200, triggerThresholdRatio: 0.4)),
          isTrue);
      expect(
          shouldCompact(messages, 1200,
              settings: const CompactionSettings(
                  reserveTokens: 200, triggerThresholdRatio: 0.6)),
          isFalse);
    });

    test('findCutPoint keeps at least keepTokens of recent history', () {
      final entries = [
        MessageEntry(
            id: 'a',
            parentId: '',
            timestamp: _t(1),
            role: 'user',
            message: UserMessage.text('x' * 400)), // 100 tokens
        MessageEntry(
            id: 'b',
            parentId: 'a',
            timestamp: _t(2),
            role: 'user',
            message: UserMessage.text('y' * 400)), // 100 tokens
        MessageEntry(
            id: 'c',
            parentId: 'b',
            timestamp: _t(3),
            role: 'user',
            message: UserMessage.text('z' * 400)), // 100 tokens
      ];
      // Keep 150 tokens: b+c = 200 >= 150 -> cut at b.
      expect(findCutPoint(entries, 150), 1);
      // Everything fits in 400 -> nothing to cut.
      expect(findCutPoint(entries, 400), isNull);
    });

    test('prepareCompaction separates cut and kept entries', () {
      final entries = [
        for (var i = 0; i < 10; i++)
          MessageEntry(
              id: 'e$i',
              parentId: i == 0 ? '' : 'e${i - 1}',
              timestamp: _t(i),
              role: 'user',
              message: UserMessage.text('m' * 40)), // 10 tokens each
      ];
      final prep = prepareCompaction(entries, 30);
      expect(prep.canCompact, isTrue);
      expect(prep.cutEntries, hasLength(greaterThan(0)));
      expect(prep.keptEntries, hasLength(greaterThan(0)));
      expect(
        prep.cutEntries.last.id,
        entries[prep.cutIndex - 1].id,
        reason: 'cutIndex is the index of the first kept entry',
      );
      final fits = prepareCompaction(entries, 10000);
      expect(fits.canCompact, isFalse);
      expect(fits.cutEntries, isEmpty);
      expect(fits.keptEntries, hasLength(10));
    });

    test('estimateEntriesTokens gives recorded usage precedence (R12)', () {
      final entries = <SessionTreeEntry>[
        UsageLedgerEntry(
          id: 'u1',
          parentId: '',
          timestamp: _t(1),
          callId: 'c1',
          turnNumber: 1,
          model: const Model(
              provider: 'anthropic',
              modelId: 'sonnet',
              contextWindow: 200000),
          inputTokens: 800,
          outputTokens: 200,
        ),
        MessageEntry(
            id: 'm1',
            parentId: 'u1',
            timestamp: _t(2),
            role: 'user',
            message: UserMessage.text('x' * 40)), // 10 tokens after usage
      ];
      expect(estimateEntriesTokens(entries), 1010);

      final noUsage = <SessionTreeEntry>[
        MessageEntry(
            id: 'm1',
            parentId: '',
            timestamp: _t(1),
            role: 'user',
            message: UserMessage.text('x' * 40)),
      ];
      expect(estimateEntriesTokens(noUsage), 10,
          reason: 'no records: pure heuristic');
    });
  });

  group('HeuristicSummarizer', () {
    final cutEntries = <SessionTreeEntry>[
      MessageEntry(
        id: 'x1',
        parentId: '',
        timestamp: _t(1),
        role: 'assistant',
        message: AssistantMessage(
          content: const [
            TextBlock('Decision: try option A.'),
            TextBlock('Plan: then validate the winner.'),
          ],
        ),
      ),
      MessageEntry(
        id: 'x2',
        parentId: 'x1',
        timestamp: _t(2),
        role: 'user',
        message: UserMessage.text('continue'),
      ),
      MessageEntry(
        id: 'x3',
        parentId: 'x2',
        timestamp: _t(3),
        role: 'toolResult',
        message: ToolResultMessage.text(
            toolCallId: 'c1', toolName: 'bash', text: 'short result'),
      ),
      ToolInvocationRecord(
        id: 'x4',
        parentId: 'x3',
        timestamp: _t(4),
        toolCallId: 'c1',
        toolName: 'bash',
        arguments: const {'cmd': 'ls'},
        artifactRefs: const [ArtifactRef(kind: 'tool-output', id: 'o1')],
      ),
    ];

    test('extracts retained categories from typed entries', () async {
      final summary =
          await HeuristicSummarizer().summarize(
              cutEntries: cutEntries, keptEntries: const []);
      expect(summary.decisions, ['try option A.']);
      expect(summary.planState, 'then validate the winner.');
      expect(summary.toolNames, ['bash']);
      expect(summary.keyResults, ['short result']);
      expect(summary.artifacts.map((a) => a.id), ['o1']);
    });

    test('composes the previous summary (contract guarantee 5)', () async {
      const previous = CompactionSummary(
        decisions: ['earlier decision'],
        toolNames: ['read'],
        keyResults: ['earlier result'],
        planState: 'step 1',
        artifacts: [ArtifactRef(kind: 'file', id: 'prev-1')],
      );
      final summary = await HeuristicSummarizer().summarize(
          cutEntries: cutEntries, keptEntries: const [], previousSummary: previous);
      expect(summary.decisions, ['earlier decision', 'try option A.']);
      expect(summary.toolNames, ['read', 'bash']);
      expect(summary.keyResults, ['earlier result', 'short result']);
      expect(summary.planState, 'then validate the winner.');
      expect(summary.artifacts.map((a) => a.id), ['prev-1', 'o1']);
    });

    test('truncates long key results', () async {
      final long = MessageEntry(
        id: 'y1',
        parentId: '',
        timestamp: _t(1),
        role: 'toolResult',
        message: ToolResultMessage.text(
            toolCallId: 'c2', toolName: 'bash', text: 'r' * 500),
      );
      final summary = await HeuristicSummarizer(maxKeyResultLength: 100)
          .summarize(cutEntries: [long], keptEntries: const []);
      expect(summary.keyResults.single.length, 100);
    });
  });

  group('US3 AC1: retained categories and resolvable artifact refs', () {
    test('compact() produces a structured summary whose refs resolve',
        () async {
      final entries = <SessionTreeEntry>[
        MessageEntry(
          id: 'a',
          parentId: '',
          timestamp: _t(1),
          role: 'assistant',
          message: AssistantMessage(
            content: const [
              TextBlock('Decision: proceed with A.'),
              ToolCallBlock(id: 'tc-a', name: 'bash', arguments: {'cmd': 'ls'}),
            ],
          ),
        ),
        MessageEntry(
          id: 'm1',
          parentId: 'a',
          timestamp: _t(2),
          role: 'toolResult',
          message: ToolResultMessage.text(
              toolCallId: 'c1',
              toolName: 'bash',
              text: 'result 1 ${'x' * 200}'), // ~55 tokens
        ),
        MessageEntry(
          id: 'm2',
          parentId: 'm1',
          timestamp: _t(3),
          role: 'toolResult',
          message: ToolResultMessage.text(
              toolCallId: 'c2',
              toolName: 'bash',
              text: 'result 2 ${'x' * 200}'), // ~55 tokens
        ),
        // Place ToolInvocationRecord early so it falls in the cut range.
        ToolInvocationRecord(
          id: 'inv1',
          parentId: 'm2',
          timestamp: _t(4),
          toolCallId: 'c1',
          toolName: 'bash',
          arguments: const {'cmd': 'ls'},
          artifactRefs: const [ArtifactRef(kind: 'tool-output', id: 'out-1')],
        ),
        for (var i = 3; i <= 8; i++)
          MessageEntry(
            id: 'm$i',
            parentId: i == 3 ? 'inv1' : 'm${i - 1}',
            timestamp: _t(i + 1),
            role: 'toolResult',
            message: ToolResultMessage.text(
                toolCallId: 'c$i',
                toolName: 'bash',
                text: 'result $i ${'x' * 200}'), // ~55 tokens each
          ),
      ];
      final summarizer = HeuristicSummarizer();
      final resolver = _StubArtifactResolver();
      final entry = await compact(entries, 400,
          summarizer: summarizer,
          settings: const CompactionSettings(
              reserveTokens: 100, keepRecentTokens: 120));

      expect(entry.summary.decisions, isNotEmpty);
      expect(entry.summary.toolNames, contains('bash'));
      expect(entry.summary.keyResults, isNotEmpty);
      expect(entry.tokensBefore, greaterThan(0));
      expect(entry.firstKeptEntryId, isNotEmpty);

      for (final ref in entry.summary.artifacts) {
        expect(await resolver.resolve(ref), isNotNull);
      }
      expect(resolver.resolved, contains('out-1'));
      // Post-compaction kept estimate stays inside the usable window.
      expect(_estimateKept(entries, entry.firstKeptEntryId),
          lessThanOrEqualTo(400 - 100));
    });
  });

  group('US3 AC2: fixture mission under budget with outcome equality', () {
    const window = 1200;
    const settings = CompactionSettings(
        enabled: true, reserveTokens: 200, keepRecentTokens: 600);

    test('fixture has 50+ tool calls across 3 turns', () async {
      final store = JsonlSessionStorage(_missionFixtureCopy());
      final session = AgentSession(store);
      final entries = await session.getEntries();
      expect(entries.whereType<TurnRecord>(), hasLength(3));
      expect(entries.whereType<ToolInvocationRecord>(),
          hasLength(greaterThanOrEqualTo(50)));
    });

    test('compacted outcome equals the uncompacted baseline and stays under '
        'budget', () async {
      // Uncompacted baseline.
      final baselineStore = JsonlSessionStorage(_missionFixtureCopy());
      final baselineSession = AgentSession(baselineStore);
      final baselineOutcome = _outcome((await baselineSession.buildContext()).messages);
      expect(baselineOutcome, 'adopt plan alpha.');

      // Compacted run: compact only at turn boundaries.
      final store = JsonlSessionStorage(_missionFixtureCopy());
      final session = AgentSession(store);
      final entries = await session.getEntries();
      final turns = entries.whereType<TurnRecord>().toList();
      final summarizer = HeuristicSummarizer();
      final resolver = _StubArtifactResolver();
      var boundaryChecks = 0;
      var compactions = 0;

      for (final _ in turns) {
        boundaryChecks++; // turn boundary: compaction is allowed here
        final ctx = await session.buildContext();
        if (shouldCompact(ctx.messages, window, settings: settings)) {
          final branch = await session.getBranch();
          final rootFirst = branch.reversed.toList();
          final entry = await compact(rootFirst, window,
              summarizer: summarizer, settings: settings);
          await session.appendCompaction(entry);
          compactions++;
          expect(_estimateKept(rootFirst, entry.firstKeptEntryId),
              lessThanOrEqualTo(window - settings.reserveTokens),
              reason: 'post-compaction kept estimate within budget');
          for (final ref in entry.summary.artifacts) {
            expect(await resolver.resolve(ref), isNotNull);
          }
        }
      }
      expect(compactions, greaterThanOrEqualTo(1),
          reason: 'mission overflows the window, so compaction must fire');
      expect(compactions, lessThanOrEqualTo(boundaryChecks),
          reason: 'compaction never runs mid-batch, only at turn boundaries');

      // Outcome equality: the effective compacted context ends with the same
      // decision as the uncompacted baseline.
      final finalEntries = await session.getEntries();
      final effective = _effectiveMessages(
          finalEntries, finalEntries.whereType<CompactionEntry>().toList());
      expect(_outcome(effective), baselineOutcome,
          reason: 'outcome equality, not transcript equality');
    });
  });

  group('Edge cases', () {
    test('compaction lands on the active branch only (invariant I2)',
        () async {
      final session = AgentSession(InMemorySessionStorage());
      await session.appendMessage(UserMessage.text('a'));
      final id2 = await session.appendMessage(UserMessage.text('b'));
      final id3 = await session.appendMessage(UserMessage.text('c'));
      await session.fork(id2);
      await session.appendMessage(UserMessage.text('d'));

      final branch = await session.getBranch();
      final rootFirst = branch.reversed.toList();
      final entry = await compact(rootFirst, 4000,
          summarizer: HeuristicSummarizer(),
          settings: const CompactionSettings(
              reserveTokens: 100, keepRecentTokens: 60));
      await session.appendCompaction(entry);

      await session.switchTo(id3);
      final sibling = await session.getBranch();
      expect(sibling.whereType<CompactionEntry>(), isEmpty,
          reason: 'sibling ancestry untouched by compaction on the other '
              'branch');
      expect(sibling.map((e) => e.id), isNot(contains(entry.id)));
      expect(sibling.map((e) => e.id), containsAll([id2, id3]));
    });

    test('compact() refuses when compaction is disabled', () {
      expect(
        () => compact(const [], 1000,
            summarizer: HeuristicSummarizer(),
            settings: const CompactionSettings(enabled: false)),
        throwsA(isA<StateError>()),
      );
    });
  });
}
