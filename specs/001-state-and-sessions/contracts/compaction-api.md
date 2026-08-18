# Interface Contract: Compaction & Summarization API

**Feature**: `001-state-and-sessions`  
**Date**: 2026-08-18  
**Spec**: [spec.md](../spec.md)

---

## 1. Compaction Types & Settings

```dart
/// Configuration governing context compaction thresholds and reserves.
class CompactionSettings {
  /// Whether selective compaction is enabled.
  final bool enabled;

  /// Tokens reserved for the model's response and system prompt buffer.
  final int reserveTokens;

  /// Target number of recent tokens to preserve uncompacted.
  final int keepRecentTokens;

  /// Ratio of usable window that triggers compaction (default: 0.85).
  final double triggerThresholdRatio;

  const CompactionSettings({
    this.enabled = true,
    this.reserveTokens = 16384,
    this.keepRecentTokens = 20000,
    this.triggerThresholdRatio = 0.85,
  });
}

/// Abstract contract for generating structured compaction summaries.
abstract interface class CompactionSummarizer {
  Future<CompactionSummary> summarize({
    required List<SessionTreeEntry> cutEntries,
    required List<SessionTreeEntry> keptEntries,
    CompactionSummary? previousSummary,
  });
}

/// Abstract contract for resolving preserved [ArtifactRef] instances.
abstract interface class ArtifactResolver {
  Future<Object?> resolve(ArtifactRef ref);
}
```

---

## 2. Compaction Pipeline Functions

```dart
/// Estimates total tokens for a list of [AgentMessage] instances.
int estimateContextTokens(List<AgentMessage> messages);

/// Estimates total tokens for a list of [SessionTreeEntry] instances.
///
/// Uses recorded [UsageLedgerEntry] values when available, falling back
/// to heuristic character-based estimation.
int estimateEntriesTokens(List<SessionTreeEntry> entries);

/// Evaluates whether context usage has crossed the compaction threshold.
bool shouldCompact(
  List<AgentMessage> messages,
  int contextWindow, {
  CompactionSettings settings = const CompactionSettings(),
});

/// Finds the split index separating entries to be compacted from entries to keep.
int? findCutPoint(List<SessionTreeEntry> rootFirstEntries, int keepTokens);

/// Prepares the cut and kept entry slices prior to summarization.
CompactionPreparation prepareCompaction(
  List<SessionTreeEntry> rootFirstEntries,
  int keepTokens,
);

/// Executes selective compaction across the active branch entries.
Future<CompactionEntry> compact(
  List<SessionTreeEntry> rootFirstEntries,
  int contextWindow, {
  required CompactionSummarizer summarizer,
  CompactionSettings settings = const CompactionSettings(),
});
```

---

## 3. Heuristic Summarizer Default

```dart
/// Built-in rule-based summarizer extracting decisions, tools, and outputs.
class HeuristicSummarizer implements CompactionSummarizer {
  final int maxKeyResultLength;

  const HeuristicSummarizer({this.maxKeyResultLength = 300});

  @override
  Future<CompactionSummary> summarize({
    required List<SessionTreeEntry> cutEntries,
    required List<SessionTreeEntry> keptEntries,
    CompactionSummary? previousSummary,
  }) async {
    // 1. Extract 'Decision:' text lines from assistant messages
    // 2. Extract unique tool names from tool results and invocations
    // 3. Extract key results from tool outputs (truncated to maxKeyResultLength)
    // 4. Extract 'Plan:' or latest plan state
    // 5. Aggregate ArtifactRef pointers from ToolInvocationRecords
    // 6. Merge with previousSummary if present
  }
}
```

---

## 4. Contract Guarantees

1. **Turn-Boundary Execution**: Compaction must only execute at turn boundaries, never in the middle of a tool execution batch.
2. **Branch Isolation**: A `CompactionEntry` appended to branch A does not mutate or affect ancestor or sibling branch B.
3. **Artifact Retrievability**: All `ArtifactRef` IDs generated during compaction must be resolvable by an `ArtifactResolver`.
4. **Outcome Parity**: Compacted context must preserve essential decisions and plan state, resulting in outcome equality against uncompacted runs (SC-002).
