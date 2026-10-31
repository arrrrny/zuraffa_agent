// Epic #1 R2/#3 acceptance — "50+ tool-call fixture mission stays under
// context budget with no outcome regression".
//
// Loads the committed 52-tool-call mission fixture
// (test/fixtures/mission_50.jsonl — 210 tree entries, model contextWindow
// 8192), runs the selective compaction pipeline (compaction.dart `compact()`
// with the HeuristicSummarizer), and asserts the three acceptance properties:
//
//   AC3a — the raw mission exceeds the context budget (compaction must engage);
//   AC3b — after compaction the active context (kept tail + CompactionEntry)
//          stays under the mission's contextWindow;
//   AC3c — NO OUTCOME REGRESSION: the structured summary carries every tool
//          used during the mission and a non-empty key-result record, and the
//          kept tail still chains onto a live entry id (nothing orphaned).

import 'dart:io';

import 'package:test/test.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

const _contextWindow = 8192; // the fixture's model contextWindow

CompactionSettings _settings() =>
    const CompactionSettings(keepRecentTokens: 4500);

Future<List<SessionTreeEntry>> _loadFixtureEntries() async {
  final tmpDir = await Directory.systemTemp.createTemp('compaction_ac3_');
  final tmpPath = '${tmpDir.path}/mission.jsonl';
  final fixtureFile = File('test/fixtures/mission_50.jsonl');
  addTearDown(() => tmpDir.delete(recursive: true));
  await fixtureFile.copy(tmpPath);

  final store = JsonlSessionStorage(tmpPath);
  final result = await store.init();
  expect(result.tearReport, isNull, reason: 'fixture must load without tears');
  final entries = await store.getEntries();
  await store.close();
  expect(entries.length, result.loadedEntriesCount);
  return entries;
}

int _toolInvocationCount(List<SessionTreeEntry> entries) =>
    entries.whereType<ToolInvocationEntry>().length;

void main() {
  group('epic R2 AC3 — 50+ tool-call fixture mission under budget', () {
    test(
      'the 52-tool mission reduces to a kept tail + summary that stays under the context window',
      () async {
        final entries = await _loadFixtureEntries();

        // The fixture IS a 50+ tool-call mission.
        expect(_toolInvocationCount(entries), greaterThanOrEqualTo(50));

        final result = await compact(
          entries,
          _contextWindow,
          summarizer: const HeuristicSummarizer(),
          settings: _settings(),
        );

        // AC3a — compaction actually engaged: the pre-compaction context was
        // over budget and the compacted context is a fraction of it.
        final before = result.entry.tokensBefore;
        final after = result.entry.tokensAfter;
        expect(before, greaterThan(_contextWindow));
        expect(after, lessThan(before));

        // AC3b — the active context stays under the mission's window.
        expect(after, lessThan(_contextWindow));

        // AC3c — no outcome regression: the summary records EVERY distinct
        // tool used in the compacted region — the cut slice this compaction
        // actually summarized, recomputed with the same deterministic cut
        // the pipeline used — plus its key-result ledger.
        final preparation = prepareCompaction(entries, _settings().keepRecentTokens);
        final toolsUsed = preparation.cutEntries
            .whereType<ToolInvocationEntry>()
            .map((e) => e.record.toolName)
            .toSet();
        expect(toolsUsed, hasLength(greaterThanOrEqualTo(6)));
        expect(result.summary.toolNames, containsAll(toolsUsed));
        expect(result.summary.keyResults, isNotEmpty);

        // The kept tail chains onto a real entry (nothing orphaned).
        final keptIds = entries.map((e) => e.id).toSet();
        expect(result.entry.firstKeptEntryId, isIn(keptIds));
      },
    );
  });
}
