// Compaction orchestration tests.
//
// Exercises token estimation, threshold detection, cut-point calculation,
// HeuristicSummarizer, and the compact() pipeline function.

import 'package:test/test.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

void main() {
  final fixedTime = DateTime.utc(2026, 1, 15, 12, 0, 0);

  group('estimateContextTokens', () {
    test('returns reasonable count for text messages', () {
      final messages = [
        UserMessage.text('Hello, this is a test message with some words.'),
        AssistantMessage.text('I will help you with that task.'),
      ];
      final tokens = estimateContextTokens(messages);
      expect(tokens, greaterThan(0));
      // ~4 chars per token; two short messages should be under 50 tokens.
      expect(tokens, lessThan(50));
    });

    test('returns zero for empty list', () {
      expect(estimateContextTokens([]), 0);
    });
  });

  group('estimateEntriesTokens', () {
    test('uses UsageLedgerEntry token counts when available', () {
      final entries = [
        UsageEntry(
          id: 'e_1',
          parentId: null,
          timestamp: fixedTime,
          record: UsageLedgerEntry(
            id: 'ul_1',
            parentId: 'e_1',
            timestamp: fixedTime,
            callId: 'c_1',
            turnNumber: 1,
            inputTokens: 500,
            outputTokens: 250,
            cacheReadTokens: 0,
            cacheWriteTokens: 0,
          ),
        ),
      ];
      final tokens = estimateEntriesTokens(entries);
      expect(tokens, 750); // 500 + 250
    });

    test('estimates message tokens heuristically', () {
      final entries = [
        MessageEntry(
          id: 'e_1',
          parentId: null,
          timestamp: fixedTime,
          message: UserMessage.text('Hello world'),
        ),
      ];
      final tokens = estimateEntriesTokens(entries);
      expect(tokens, greaterThan(0));
    });

    test('adds overhead for tool invocations', () {
      final entries = [
        ToolInvocationEntry(
          id: 'e_1',
          parentId: null,
          timestamp: fixedTime,
          record: ToolInvocationRecord(
            id: 'ti_1',
            timestamp: fixedTime,
            toolCallId: 'tc_1',
            toolName: 'search',
            isError: false,
            durationMs: 100,
          ),
        ),
      ];
      final tokens = estimateEntriesTokens(entries);
      expect(tokens, 100); // Fixed overhead
    });
  });

  group('shouldCompact', () {
    test('returns true when above threshold', () {
      // Create messages that exceed 85% of usable window.
      // ~50 chars per message => ~12.5 tokens per message.
      // 200 messages => ~2500 tokens.
      // With reserveTokens=100, contextWindow=2500, usable=2400, threshold=2040.
      final messages = List.generate(
        200,
        (i) => UserMessage.text('Message $i with enough text to use tokens'),
      );
      expect(
        shouldCompact(
          messages,
          2500,
          settings: const CompactionSettings(reserveTokens: 100),
        ),
        isTrue,
      );
    });

    test('returns false when below threshold', () {
      // 10 messages => ~38 tokens.
      // With reserveTokens=100, contextWindow=8192, usable=8092, threshold=6878.
      final messages = List.generate(
        10,
        (i) => UserMessage.text('Short message $i'),
      );
      expect(
        shouldCompact(
          messages,
          8192,
          settings: const CompactionSettings(reserveTokens: 100),
        ),
        isFalse,
      );
    });

    test('returns false when disabled', () {
      final messages = List.generate(
        200,
        (i) => UserMessage.text('Long message $i with lots of content here'),
      );
      expect(
        shouldCompact(
          messages,
          2000,
          settings: const CompactionSettings(enabled: false),
        ),
        isFalse,
      );
    });
  });

  group('findCutPoint', () {
    test('returns null when everything fits', () {
      final entries = [
        MessageEntry(
          id: 'e_1',
          parentId: null,
          timestamp: fixedTime,
          message: UserMessage.text('hi'),
        ),
      ];
      expect(findCutPoint(entries, 10000), isNull);
    });

    test('returns index when entries exceed keepTokens', () {
      final entries = List.generate(
        10,
        (i) => UsageEntry(
          id: 'e_$i',
          parentId: i > 0 ? 'e_${i - 1}' : null,
          timestamp: fixedTime.add(Duration(seconds: i)),
          record: UsageLedgerEntry(
            id: 'ul_$i',
            parentId: i > 0 ? 'e_${i - 1}' : null,
            timestamp: fixedTime.add(Duration(seconds: i)),
            callId: 'c_$i',
            turnNumber: i + 1,
            inputTokens: 500,
            outputTokens: 250,
            cacheReadTokens: 0,
            cacheWriteTokens: 0,
          ),
        ),
      );
      // Total tokens: 10 * 750 = 7500. keepTokens=2000.
      final cutIdx = findCutPoint(entries, 2000);
      expect(cutIdx, isNotNull);
      expect(cutIdx!, greaterThan(0));
      expect(cutIdx, lessThan(10));
    });
  });

  group('prepareCompaction', () {
    test('returns empty cut when everything fits', () {
      final entries = [
        MessageEntry(
          id: 'e_1',
          parentId: null,
          timestamp: fixedTime,
          message: UserMessage.text('hi'),
        ),
      ];
      final prep = prepareCompaction(entries, 10000);
      expect(prep.cutEntries, isEmpty);
      expect(prep.keptEntries, hasLength(1));
    });

    test('splits entries at correct boundary', () {
      final entries = List.generate(
        5,
        (i) => UsageEntry(
          id: 'e_$i',
          parentId: null,
          timestamp: fixedTime.add(Duration(seconds: i)),
          record: UsageLedgerEntry(
            id: 'ul_$i',
            parentId: null,
            timestamp: fixedTime.add(Duration(seconds: i)),
            callId: 'c_$i',
            turnNumber: i + 1,
            inputTokens: 1000,
            outputTokens: 500,
            cacheReadTokens: 0,
            cacheWriteTokens: 0,
          ),
        ),
      );
      // Total: 5 * 1500 = 7500. keepTokens=3000.
      final prep = prepareCompaction(entries, 3000);
      expect(prep.cutEntries, isNotEmpty);
      expect(prep.keptEntries, isNotEmpty);
      expect(prep.cutEntries.length + prep.keptEntries.length, 5);
    });
  });

  group('HeuristicSummarizer', () {
    late HeuristicSummarizer summarizer;

    setUp(() {
      summarizer = const HeuristicSummarizer();
    });

    test('extracts decisions from Decision: lines', () async {
      final cutEntries = [
        MessageEntry(
          id: 'e_1',
          parentId: null,
          timestamp: fixedTime,
          message: AssistantMessage(
            content: [
              TextBlock('Decision: use Hive for storage'),
              TextBlock('Decision: implement JSONL fallback'),
            ],
          ),
        ),
      ];
      final summary = await summarizer.summarize(
        cutEntries: cutEntries,
        keptEntries: const [],
      );
      expect(summary.decisions, hasLength(2));
      expect(summary.decisions, contains('use Hive for storage'));
    });

    test('extracts tool names from ToolInvocationEntry', () async {
      final cutEntries = [
        ToolInvocationEntry(
          id: 'e_1',
          parentId: null,
          timestamp: fixedTime,
          record: ToolInvocationRecord(
            id: 'ti_1',
            timestamp: fixedTime,
            toolCallId: 'tc_1',
            toolName: 'search',
            isError: false,
            durationMs: 100,
          ),
        ),
        ToolInvocationEntry(
          id: 'e_2',
          parentId: 'e_1',
          timestamp: fixedTime,
          record: ToolInvocationRecord(
            id: 'ti_2',
            parentId: 'e_1',
            timestamp: fixedTime,
            toolCallId: 'tc_2',
            toolName: 'read',
            isError: false,
            durationMs: 50,
          ),
        ),
      ];
      final summary = await summarizer.summarize(
        cutEntries: cutEntries,
        keptEntries: const [],
      );
      expect(summary.toolNames, containsAll(['search', 'read']));
    });

    test('merges with previous summary', () async {
      final previous = CompactionSummary(
        decisions: ['prior decision'],
        toolNames: ['prior_tool'],
        keyResults: ['prior result'],
      );
      final summary = await summarizer.summarize(
        cutEntries: [
          MessageEntry(
            id: 'e_1',
            parentId: null,
            timestamp: fixedTime,
            message: AssistantMessage(
              content: [TextBlock('Decision: new decision')],
            ),
          ),
        ],
        keptEntries: const [],
        previousSummary: previous,
      );
      expect(
        summary.decisions,
        containsAll(['prior decision', 'new decision']),
      );
      expect(summary.toolNames, contains('prior_tool'));
    });

    test('retains error toolResults with an explicit [error] marker', () async {
      final cutEntries = [
        MessageEntry(
          id: 'e_1',
          parentId: null,
          timestamp: fixedTime,
          message: ToolResultMessage(
            toolCallId: 'tc_1',
            toolName: 'bash',
            content: 'exit code 1: command not found',
            isError: true,
          ),
        ),
      ];
      final summary = await summarizer.summarize(
        cutEntries: cutEntries,
        keptEntries: const [],
      );
      expect(summary.keyResults, hasLength(1));
      expect(summary.keyResults.single, startsWith('[error] '));
      expect(summary.keyResults.single, contains('bash: exit code 1'));
    });

    test('truncates toolResult content beyond maxKeyResultLength', () async {
      const maxLen = 300;
      final content = 'HEAD${'x' * (maxLen + 50)}TAIL_MARKER';
      final cutEntries = [
        MessageEntry(
          id: 'e_1',
          parentId: null,
          timestamp: fixedTime,
          message: ToolResultMessage(
            toolCallId: 'tc_1',
            toolName: 'grep',
            content: content,
          ),
        ),
      ];
      final summary = await summarizer.summarize(
        cutEntries: cutEntries,
        keptEntries: const [],
      );
      final row = summary.keyResults.single;
      expect(row, startsWith('grep: HEAD'));
      expect(row, endsWith('…'));
      expect(row, isNot(contains('TAIL_MARKER')));
      expect(row.length, lessThanOrEqualTo(maxLen + 1));
    });

    test('truncation never splits a UTF-16 surrogate pair', () async {
      // The emoji straddles the final re-truncation boundary in UTF-16
      // units ('grep: ' + 293 a's puts the emoji's high surrogate at row
      // unit 299): the pre-fix substring cut kept that lone high surrogate
      // and dropped its low half. The code-point cut keeps the emoji whole.
      final content = '${'a' * 293}😀TAIL';
      final cutEntries = [
        MessageEntry(
          id: 'e_1',
          parentId: null,
          timestamp: fixedTime,
          message: ToolResultMessage(
            toolCallId: 'tc_1',
            toolName: 'grep',
            content: content,
          ),
        ),
      ];
      final summary = await summarizer.summarize(
        cutEntries: cutEntries,
        keptEntries: const [],
      );
      final row = summary.keyResults.single;
      expect(row, contains('😀'));
      for (final rune in row.runes) {
        expect(
          rune < 0xD800 || rune > 0xDFFF,
          isTrue,
          reason: 'lone surrogate U+${rune.toRadixString(16)} in summary',
        );
      }
    });

    test(
      'does not double-record a call whose result message is in the cut region',
      () async {
        final cutEntries = [
          ToolInvocationEntry(
            id: 'ti_entry',
            parentId: null,
            timestamp: fixedTime,
            record: ToolInvocationRecord(
              id: 'ti_1',
              timestamp: fixedTime,
              toolCallId: 'tc_1',
              toolName: 'search',
              resultEntryId: 'result_entry',
              isError: false,
              durationMs: 12,
            ),
          ),
          MessageEntry(
            id: 'result_entry',
            parentId: null,
            timestamp: fixedTime,
            message: ToolResultMessage(
              toolCallId: 'tc_1',
              toolName: 'search',
              content: 'found 3 files',
            ),
          ),
        ];
        final summary = await summarizer.summarize(
          cutEntries: cutEntries,
          keptEntries: const [],
        );
        expect(summary.keyResults, [
          'search: found 3 files',
        ], reason: 'the id-reference row is superseded by the content row');
      },
    );

    test(
      'keeps the id-reference row when the result message is outside the cut region',
      () async {
        final cutEntries = [
          ToolInvocationEntry(
            id: 'ti_entry',
            parentId: null,
            timestamp: fixedTime,
            record: ToolInvocationRecord(
              id: 'ti_1',
              timestamp: fixedTime,
              toolCallId: 'tc_1',
              toolName: 'search',
              resultEntryId: 'result_entry',
              isError: false,
              durationMs: 12,
            ),
          ),
        ];
        final summary = await summarizer.summarize(
          cutEntries: cutEntries,
          keptEntries: const [],
        );
        expect(summary.keyResults, ['search: result result_entry']);
      },
    );
  });

  group('estimateSummaryTokens', () {
    test('empty summary stays near the wrapper-tag floor', () {
      final empty = CompactionSummary(
        decisions: [],
        toolNames: [],
        keyResults: [],
      );
      final tokens = estimateSummaryTokens(empty);
      expect(tokens, greaterThanOrEqualTo(30)); // 120 wrapper chars / 4
      expect(tokens, lessThan(60));
    });

    test('scales with content-bearing key results, not a fixed allowance', () {
      final empty = CompactionSummary(
        decisions: [],
        toolNames: [],
        keyResults: [],
      );
      final fat = CompactionSummary(
        decisions: const [],
        toolNames: const ['bash'],
        keyResults: List.generate(52, (i) => 'bash: ${'r' * 300}'),
      );
      expect(
        estimateSummaryTokens(fat),
        greaterThan(estimateSummaryTokens(empty) + 3000),
      );
    });
  });

  group('compact()', () {
    test('returns CompactionResult with entry and summary', () async {
      final entries = List.generate(
        10,
        (i) => UsageEntry(
          id: 'e_$i',
          parentId: i > 0 ? 'e_${i - 1}' : null,
          timestamp: fixedTime.add(Duration(seconds: i)),
          record: UsageLedgerEntry(
            id: 'ul_$i',
            parentId: i > 0 ? 'e_${i - 1}' : null,
            timestamp: fixedTime.add(Duration(seconds: i)),
            callId: 'c_$i',
            turnNumber: i + 1,
            inputTokens: 1000,
            outputTokens: 500,
            cacheReadTokens: 0,
            cacheWriteTokens: 0,
          ),
        ),
      );

      final result = await compact(
        entries,
        10000,
        summarizer: const HeuristicSummarizer(),
        settings: const CompactionSettings(keepRecentTokens: 2000),
      );

      expect(result, isA<CompactionResult>());
      expect(result.entry, isA<CompactionEntry>());
      expect(result.summary, isA<CompactionSummary>());
      expect(result.entry.tokensBefore, greaterThan(0));
      expect(result.entry.tokensAfter, lessThan(result.entry.tokensBefore));
    });

    test('returns empty summary when nothing to compact', () async {
      final entries = [
        MessageEntry(
          id: 'e_1',
          parentId: null,
          timestamp: fixedTime,
          message: UserMessage.text('hi'),
        ),
      ];

      final result = await compact(
        entries,
        10000,
        summarizer: const HeuristicSummarizer(),
      );

      expect(result.summary.decisions, isEmpty);
      expect(result.summary.toolNames, isEmpty);
    });
  });
}
