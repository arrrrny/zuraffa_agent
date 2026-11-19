// RunUsage — a seam-level accumulator (issue #191) that folds
// LlmResponse.usage into UsageEntry rows the exported UsageLedger projects.
//
// The lean typed seam returns usage on every response; a run that collects
// its responses in one RunUsage can report tokens per run without any
// per-consumer accounting code.

import 'llm/llm_client.dart';
import 'types.dart';

/// One folded turn: the usage of a single response, in fold order.
class RunUsageTurn {
  /// The prompt tokens reported for this turn.
  final int promptTokens;

  /// The completion tokens reported for this turn.
  final int completionTokens;

  /// The cached (cache-read) tokens reported for this turn.
  final int cachedTokens;

  /// The thought tokens reported for this turn.
  final int thoughtTokens;

  /// Creates a folded-turn record.
  const RunUsageTurn({
    this.promptTokens = 0,
    this.completionTokens = 0,
    this.cachedTokens = 0,
    this.thoughtTokens = 0,
  });
}

/// Accumulates [LlmUsage] values across a run and emits [UsageEntry] rows
/// loadable by [UsageLedger].
///
/// Fold order is preserved: turn N maps to entry N, and [UsageEntry.model]
/// carries the caller-supplied model attribution (provider + model id).
class RunUsage {
  final List<RunUsageTurn> _turns = [];

  /// Folds one response's usage into the run (issue #191).
  ///
  /// A response with default (all-zero) usage still counts as a turn — the
  /// fold is per turn, not per billed token.
  void add(LlmResponse response) {
    _turns.add(
      RunUsageTurn(
        promptTokens: response.usage.inputTokens,
        completionTokens: response.usage.outputTokens,
        cachedTokens: response.usage.cachedTokens,
        thoughtTokens: response.usage.thoughtTokens,
      ),
    );
  }

  /// Total input tokens across every folded response.
  int get totalPromptTokens => _turns.fold(0, (sum, t) => sum + t.promptTokens);

  /// Total output tokens across every folded response.
  int get totalCompletionTokens =>
      _turns.fold(0, (sum, t) => sum + t.completionTokens);

  /// Total cached (cache-read) tokens across every folded response.
  int get totalCachedTokens => _turns.fold(0, (sum, t) => sum + t.cachedTokens);

  /// Total thought tokens across every folded response.
  int get totalThoughtTokens =>
      _turns.fold(0, (sum, t) => sum + t.thoughtTokens);

  /// Prompt + completion tokens (cache and thought are informational
  /// subsets, not additive — same convention as UsageLedger).
  int get totalTokens => totalPromptTokens + totalCompletionTokens;

  /// Number of responses folded (one entry per turn).
  int get length => _turns.length;

  /// Builds one [UsageEntry] per folded response, ready to wrap in a
  /// [UsageLedger] (or append via `Session.appendUsage`).
  ///
  /// [provider] and [model] attribute every entry; a null [provider] leaves
  /// [UsageEntry.model] null rather than synthesizing a nameless, 0-window
  /// model — a fabricated `contextWindow: 0` would drive the session's
  /// pre-flight threshold to 0 and attribute usage to an empty provider.
  /// Pass [contextWindow] (the model's real window) when [provider] is set so
  /// downstream consumers get a usable attribution. [at] is the entry
  /// timestamp.
  ///
  /// Ids are globally unique by default (`generateEntryId`) so two runs folded
  /// into one ledger never collide on [UsageLedger.prune]'s id-keyed victim
  /// set or [SessionStorage]'s entry keys. Pass [idPrefix] for a deterministic
  /// `<idPrefix>-<n>` / `<idPrefix>-<n>-usage` form (tests). The parent id is
  /// left null — the sink owns tree linkage.
  List<UsageEntry> toUsageEntries({
    required String model,
    DateTime? at,
    String? provider,
    int? contextWindow,
    String? idPrefix,
  }) {
    final timestamp = at ?? DateTime.now().toUtc();
    final modelRef = provider == null
        ? null
        : Model(
            provider: provider,
            modelId: model,
            contextWindow: contextWindow ?? 0,
          );
    return [
      for (var i = 0; i < _turns.length; i++)
        UsageEntry(
          id: idPrefix == null ? generateEntryId() : '$idPrefix-${i + 1}',
          timestamp: timestamp,
          record: UsageLedgerEntry(
            id: idPrefix == null
                ? generateEntryId()
                : '$idPrefix-${i + 1}-usage',
            timestamp: timestamp,
            callId: idPrefix == null ? generateEntryId() : '$idPrefix-${i + 1}',
            turnNumber: i + 1,
            inputTokens: _turns[i].promptTokens,
            outputTokens: _turns[i].completionTokens,
            cacheReadTokens: _turns[i].cachedTokens,
            cacheWriteTokens: 0,
          ),
          model: modelRef,
        ),
    ];
  }
}
