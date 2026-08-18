# Contract: Compaction API (`zuraffa_agent`)

**Feature**: `002-state-and-sessions`

Selective structured compaction — never naive truncation (FR-004). Replaces
pi_agent's placeholder summarizer.

## Types

```dart
typedef TokenEstimator = int Function(List<AgentMessage> messages);

class CompactionSettings {        // ported defaults
  final bool enabled;             // true
  final int reserveTokens;        // 16384
  final int keepRecentTokens;     // 20000
  final int triggerThresholdRatio; // NEW: compact when estimate > (contextWindow - reserve)
}

class CompactionSummary {         // NEW — structured, retained categories
  final List<String> decisions;
  final List<String> toolNames;
  final List<String> keyResults;
  final String? planState;
  final List<ArtifactRef> artifacts;
  final String? prose;
}

class ArtifactRef {               // NEW — opaque, resolvable
  final String kind;              // e.g. 'tool-output', 'file'
  final String id;                // artifact store key (spec 003)
}

abstract class ArtifactResolver { // NEW — implemented by spec 003 artifact store
  Future<Object?> resolve(ArtifactRef ref);
}

abstract class CompactionSummarizer {          // NEW — injectable
  Future<CompactionSummary> summarize({
    required List<SessionTreeEntry> cutEntries,
    required List<SessionTreeEntry> keptEntries,
    CompactionSummary? previousSummary,
    String? customInstructions,
  });
}

class HeuristicSummarizer implements CompactionSummarizer { ... } // default
```

## Functions (ported, reworked)

```dart
int estimateContextTokens(List<AgentMessage> messages);  // chars/4 default estimator
bool shouldCompact(List<AgentMessage> messages, int contextWindow, {CompactionSettings settings});
int? findCutPoint(List<SessionTreeEntry> entries, int keepTokens);
CompactionPreparation prepareCompaction(List<SessionTreeEntry> entries, int keepTokens);
Future<CompactionEntry> compact(
  List<SessionTreeEntry> entries,
  int contextWindow, {
  required CompactionSummarizer summarizer,   // was placeholder-internal
  CompactionSettings? settings,
  String? customInstructions,
  CompactionSummary? previousSummary,
});
```

## Behavioral guarantees

1. Retained categories survive: decisions, tool names, key results, plan
   state appear as typed fields on `CompactionSummary` (US3 AC1).
2. Discarded material is represented by `ArtifactRef`s that `ArtifactResolver`
   can resolve (US3 AC1 — "resolvable").
3. Compaction runs at turn boundaries only; the API is synchronous-safe to
   call between turns and `shouldCompact` is cheap enough to poll per turn
   (edge case: never mid-batch).
4. A `CompactionEntry` is appended to the active branch; sibling branches'
   ancestry is untouched (edge case, invariant I2).
5. Summaries compose: `previousSummary` folds into the next summary rather
   than accumulating raw text (50+ iteration trajectory goal).
6. Budget math: post-compaction context estimate ≤ contextWindow − reserve;
   fixture missions stay under budget with outcome equality vs uncompacted
   baselines (SC-002, outcome equality not transcript equality).
