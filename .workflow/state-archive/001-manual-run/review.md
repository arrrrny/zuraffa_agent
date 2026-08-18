# CodeRabbit-Style Review: arrrrny/zuraffa_agent#9

**PR**: [#9 — 001-state-and-sessions: Granular typed session tree & compaction](https://github.com/arrrrny/zuraffa_agent/pull/9)
**Base**: `main` ← **Head**: `001-state-and-sessions`
**Author**: arrrrny
**Date**: 2026-08-18

---

## Walkthrough

This PR lands the core state-and-sessions foundation: selective structured compaction engine and hand-written Hive TypeAdapters for every sealed entity/message type. These are the two new files that sit on top of the types/storage layer already merged.

| Layer / File(s) | Summary |
|---|---|
| `lib/src/compaction.dart` (435 lines, NEW) | Selective structured compaction: `HeuristicSummarizer` extracts decisions/tool-names/key-results/plan-state from typed entries; `ArtifactRef` + `ArtifactResolver` for discarded material; `compact()` orchestrates cut-point search → summarize → produce `CompactionEntry`. Ported from pi_agent with MIT attribution header. |
| `lib/src/hive_adapters.dart` (746 lines, NEW) | Hand-written Hive `TypeAdapter`s for 25 types: 4 messages, 6 content blocks, 10 session-tree entries, 5 support value objects. Deterministic type IDs pinned by `HiveTypeIds`. `registerZuraffaAdapters()` is idempotent. Shared `_writeBase`/`_readBase` helpers keep serialization DRY. |
| `specs/001-state-and-sessions/tasks.md` (245 lines, NEW) | Task tracking — all US1/US2/US3 tasks marked complete. |
| `test/compaction_test.dart` (473 lines, NEW) | US3 acceptance tests: token estimation, cut-point search, `HeuristicSummarizer` category extraction, compaction on active branch only (invariant I2), 50+ tool-call fixture stays under budget with outcome equality (SC-002). |
| `test/session_test.dart` (431 lines, NEW) | US2 acceptance tests: fork/switch/deleteBranch/prune, close/reopen restart (AC3), `appendTurn` cross-branch rejection, `appendCompaction` leaf-parent check. Parameterized across InMemory/JSONL/Hive. |
| `test/session_storage_test.dart` (412 lines, NEW) | US1 storage contract: round-trip every entry type, persistence across close/reopen, JSONL tear handling (corrupt tail, blank lines, missing file), 200-entry performance regression test. |
| `test/fixtures/mission_50.jsonl` | Deterministic 50+ tool-call fixture across 3 turns for compaction budget testing. |

**Estimated review effort**: 3/5 (~25 min) — two new production files, both well-documented; the bulk of review is verifying adapter correctness and compaction pipeline threading.

---

## Pre-Merge Checks

| Check | Status |
|---|---|
| Attribution headers on ported code | ✅ `compaction.dart:1-3` carries BSD-3→MIT attribution referencing pi_agent source path and NOTICE. `hive_adapters.dart:1-3` carries MIT header (new file, no pi_agent equivalent). |
| No `dart:io` in engine runtime paths (`lib/src/`) | ✅ `Grep` confirms zero `dart:io` imports in `lib/src/`. |
| Tests meaningful, not tautological | ✅ Tests validate structural invariants (branch isolation, token budgets, outcome equality, tear handling) — not just `expect(x, x)`. |
| Spec acceptance scenarios covered | ✅ US1 AC1 (round-trip), US2 AC1-3 (fork/switch/restart), US3 AC1-2 (retained categories +50-call fixture), SC-001-004 all covered by parameterized test suites. |
| `pubspec.yaml` / `analysis_options.yaml` | Not in this diff — pre-existing. |

---

## Findings

### 🔴 Critical

*No critical findings.*

---

### 🟠 Major

#### 1. 🟠 Major — `CompactionPreparation.previousSummary` is `String?` but unused; type mismatch with `CompactionSummary`

**File**: `lib/src/compaction.dart:334`
**Category**: 🎯 Functional Correctness
**Effort**: 🔨 Medium

`CompactionPreparation.previousSummary` is declared as `String?` (line 334), and `prepareCompaction()` accepts `String?` (line 353). However, `compact()` passes `previousSummary: CompactionSummary?` directly to `summarize()` (line 398) and **never** passes it through `prepareCompaction`. The field in `CompactionPreparation` is dead code — it's stored but never read by any consumer.

This creates a confusing dual interface: the public `CompactionPreparation` API suggests summaries flow through preparation, but they don't. Worse, if a future caller passes `previousSummary` to `prepareCompaction`, it arrives as a `String` while `summarize()` expects `CompactionSummary?` — a latent type error.

**Proposed fix**: Remove the `previousSummary` field from `CompactionPreparation` and the `previousSummary` parameter from `prepareCompaction()`. The `previousSummary` already flows correctly through `compact()` → `summarize()`.

```dart
// CompactionPreparation — remove previousSummary field:
class CompactionPreparation {
  final int cutIndex;
  final int tokensCut;
  final List<SessionTreeEntry> keptEntries;
  final List<SessionTreeEntry> cutEntries;
  // REMOVED: final String? previousSummary;

  bool get canCompact => cutIndex > 0;

  const CompactionPreparation({
    required this.cutIndex,
    required this.tokensCut,
    required this.keptEntries,
    required this.cutEntries,
    // REMOVED: this.previousSummary,
  });
}

// prepareCompaction — remove previousSummary parameter:
CompactionPreparation prepareCompaction(
  List<SessionTreeEntry> entries,
  int keepTokens,
) {
  // ... existing logic unchanged ...
}
```

<details>
<summary>🤖 Prompt for AI Agents</summary>

Remove the unused `previousSummary` field from `CompactionPreparation` (line 334) and the `previousSummary` parameter from `prepareCompaction()` (line 353). The `compact()` function already passes `previousSummary` directly to `summarize()`, so this dead field is misleading. Update all call sites of `prepareCompaction` (only `compact()` at line 393, which doesn't pass the param — so no call-site changes needed).
</details>

---

#### 2. 🟠 Major — Unsafe `.cast<>()` in Hive adapter readers

**File**: `lib/src/hive_adapters.dart:138-139` and `:572`
**Category**: 🎯 Functional Correctness
**Effort**: ⚡ Quick win

`_readContentBlocks` (line 138) does `r.readList().cast<ContentBlock>()`, and `ToolInvocationRecordAdapter.read` (line 572) does `reader.readList().cast<ArtifactRef>()`. The `.cast<T>()` method throws `TypeError` at runtime if any element isn't `T` — it's a lazy cast that defers failure to access time. If the Hive binary format ever contains a corrupt or unexpected element type, this produces a confusing `TypeError` far from the source.

Use `whereType<T>()` instead for fail-fast, clear error messages:

```dart
// _readContentBlocks (line 138):
List<ContentBlock> _readContentBlocks(BinaryReader r) =>
    r.readList().whereType<ContentBlock>().toList();

// ToolInvocationRecordAdapter.read (line 572):
artifactRefs: reader.readList().whereType<ArtifactRef>().toList(),
```

<details>
<summary>🤖 Prompt for AI Agents</summary>

Replace `.cast<ContentBlock>()` with `.whereType<ContentBlock>().toList()` in `_readContentBlocks` (line 138-139 of `lib/src/hive_adapters.dart`). Replace `.cast<ArtifactRef>()` with `.whereType<ArtifactRef>().toList()` in `ToolInvocationRecordAdapter.read` (line 572). Both changes make type mismatches fail immediately at the read site with a clear error instead of a deferred `TypeError`.
</details>

---

#### 3. 🟠 Major — Inline adapter instantiation in `AssistantMessageAdapter.read`

**File**: `lib/src/hive_adapters.dart:172`
**Category**: 🩺 Stability & Availability
**Effort**: ⚡ Quick win

`AssistantMessageAdapter.read()` creates a new `UsageAdapter()` instance inline at line 172:

```dart
usage: reader.readBool() ? UsageAdapter().read(reader) : null,
```

This bypasses Hive's adapter registry and creates a throwaway object per read. While functionally correct today (the adapter is self-contained), it violates the registration contract — if `UsageAdapter` is ever registered with Hive-specific wrapping or state, this direct instantiation would skip it. The same pattern is used correctly everywhere else in the file (e.g., `CompactionEntryAdapter` uses `reader.read()` which dispatches through the registry).

**Proposed fix**: Use `reader.read() as Usage?` to dispatch through Hive's registered adapter, matching the pattern used by `CompactionEntryAdapter` (line 429) and `UsageLedgerEntryAdapter` (line 603):

```dart
// line 172 — before:
usage: reader.readBool() ? UsageAdapter().read(reader) : null,

// after:
usage: reader.readBool() ? reader.read() as Usage : null,
```

<details>
<summary>🤖 Prompt for AI Agents</summary>

In `AssistantMessageAdapter.read()` at `lib/src/hive_adapters.dart:172`, replace `UsageAdapter().read(reader)` with `reader.read() as Usage` to dispatch through Hive's adapter registry. This matches the pattern used by `CompactionEntryAdapter` (line 429) and `UsageLedgerEntryAdapter` (line 603), ensuring consistent adapter dispatch.
</details>

---

### 🟡 Minor

#### 4. 🟡 Minor — `HeuristicSummarizer.addToolName` uses O(n) list search for deduplication

**File**: `lib/src/compaction.dart:169-171`
**Category**: ⚡ Performance
**Effort**: ⚡ Quick win

`addToolName` checks `toolNames.contains(name)` on a `List<String>`, which is O(n) per call. For the50+ tool-call fixture this is negligible, but for missions with hundreds of distinct tool names, this becomes O(n²). A `Set<String>` alongside the list would give O(1) membership checks while preserving insertion order for the final list:

```dart
final toolNames = <String>[];
final _toolNamesSeen = <String>{};

void addToolName(String name) {
  if (_toolNamesSeen.add(name)) toolNames.add(name);
}
```

<details>
<summary>🤖 Prompt for AI Agents</summary>

In `HeuristicSummarizer.summarize()` at `lib/src/compaction.dart:169-171`, add a `_toolNamesSeen` set alongside the `toolNames` list and use `_toolNamesSeen.add(name)` for O(1) deduplication instead of `toolNames.contains(name)`. This is a performance improvement for large tool vocabularies.
</details>

---

#### 5. 🟡 Minor — Token estimation heuristic ignores non-Latin multi-byte characters

**File**: `lib/src/compaction.dart:426`
**Category**: 🎯 Functional Correctness
**Effort**: 🔨 Medium

`_estimateMessageTokens` uses `(text.length / 4).ceil()` — a standard chars/4 heuristic that works well for Latin text. However, CJK characters, emoji, and other multi-byte Unicode can undercount token usage (a single CJK character is often 1-2 tokens, not 0.25). For compaction triggering this is conservative (undercount = delay compaction), but it could cause context-budget overruns in CJK-heavy missions.

This is acceptable for the default heuristic — the usage ledger (R12) takes precedence once real counts are available. No immediate fix required, but worth documenting.

---

#### 6. 🟡 Minor — `findCutPoint` only counts `MessageEntry` tokens, not entry metadata overhead

**File**: `lib/src/compaction.dart:301-317`
**Category**: 🎯 Functional Correctness
**Effort**: 🔨 Medium

`findCutPoint` walks entries backward and only accumulates tokens from `MessageEntry` instances (line 309). Non-message entries like `TurnRecord`, `ToolInvocationRecord`, and `UsageLedgerEntry` contribute to context size but are ignored. In practice this is conservative (fewer tokens counted → cut sooner → keep more), so it won't cause budget overruns. But it means the cut point may be more aggressive than necessary, trimming entries that could be retained.

This is acceptable for the initial implementation. A future refinement could add a per-entry overhead estimate for non-message entries.

---

### 🔵 Trivial / Nitpicks

1. **`compaction.dart:13`** — `library;` (unnamed library) is fine for Dart 3.x but means no doc on the library itself. Consider adding a one-liner: `library selective_compaction;`

2. **`hive_adapters.dart:62-67`** — The `registerZuraffaAdapters()` inner `register<T>` function creates a new adapter instance on every call even when already registered. Consider caching adapters in a map to avoid unnecessary allocations during startup.

3. **`test/compaction_test.dart:389`** — The fixture path `'test/fixtures/mission_50.jsonl'` is hardcoded. If tests ever run from a different working directory, this breaks. Consider using `Platform.script` relative resolution or a test fixture helper.

---

## Verdict

**Actionable findings: 3 Major, 3 Minor**

The PR is well-structured: both new files carry proper attribution headers, the compaction engine correctly separates cut/keep/summarize concerns, the Hive adapters are exhaustive with deterministic type IDs, and the test suites are genuinely meaningful (branch isolation, token budget, outcome equality, tear handling). The three major findings are all quick-to-fix correctness issues — none require architectural changes.

After addressing the three major items (dead `previousSummary` field, unsafe `.cast<>()`, inline adapter instantiation), this is ready to merge.

**VERDICT: APPROVE**
