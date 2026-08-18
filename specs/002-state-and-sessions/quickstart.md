# Quickstart: State & Sessions

**Feature**: `002-state-and-sessions`

Runnable validation scenarios proving the feature end-to-end. Each maps to a
spec acceptance scenario (references: [spec.md](spec.md),
[contracts/session-api.md](contracts/session-api.md),
[contracts/compaction-api.md](contracts/compaction-api.md),
[data-model.md](data-model.md)).

## Prerequisites

- Dart SDK ≥ 3.12 (`dart --version`)
- Package restored: `dart pub get` from repo root (first run creates
  `.dart_tool/`; only runtime dep is `hive_ce`)

## Setup commands

```bash
cd /path/to/zuraffa_agent
dart pub get
dart test                  # full suite (all scenarios below run as tests)
dart test test/session_test.dart          # single group
dart test --name "fork"                   # single scenario
```

The scenarios below live in `test/` and also run as plain Dart programs where
noted — no LLM keys, no network, deterministic fixtures only.

## Scenario 1 — Typed round-trip (US1 AC1, SC-003)

**File**: `test/roundtrip_test.dart` (runs against all three stores)

1. Build a mission fixture: 3 turns × (user → assistant w/ thinking + tool
   calls → tool results), each turn closed by a `TurnRecord`,
   `ToolInvocationRecord` per call, `UsageLedgerEntry` per LLM call.
2. Persist via `JsonlSessionStorage` and `HiveSessionStorage`; close and
   reopen each store.
3. Reload and assert:
   - every entry retrievable by ID via `getEntry` as its concrete typed
     subclass (no `Map<String, dynamic>` returns, no dynamic casts in the
     public API);
   - `UsageLedger.fromEntries(...)` totals equal the fixture's known token
     counts;
   - Hive and JSONL produce identical entry sequences (cross-store
     equivalence).

**Expected**: all assertions pass; grep of the public barrel shows no
`Map<String, dynamic>` in entity-returning signatures (custom extensibility
points excepted — see data-model.md).

## Scenario 2 — Branch / fork / resume (US2 AC1–3, SC-001)

**File**: `test/session_test.dart`

1. Append 3 messages; `fork` at entry 2; append 2 divergent entries on the
   new branch.
2. `switchTo` the original branch leaf → `buildContext()` must equal the
   pre-fork conversation exactly (no sibling leakage, byte-comparable message
   lists).
3. Switch back to the forked branch → context matches that branch only.
4. **Restart identity**: close the store, reopen, `buildContext()` returns
   the identical context (persisted leaf, invariant I4).

**Expected**: identical reconstructions; run on both Hive and JSONL.

## Scenario 3 — Compaction under budget (US3 AC1–2, SC-002)

**File**: `test/compaction_test.dart` + `test/fixtures/`

1. Load the 50+ tool-call fixture mission (`test/fixtures/mission_50.jsonl`).
2. Run once uncompacted against a small synthetic context window; record the
   baseline outcome (fixture defines outcome as a deterministic checker
   result, not transcript).
3. Run compacted with `HeuristicSummarizer`: assert
   - `CompactionSummary` retains decisions / toolNames / keyResults /
     planState;
   - every `ArtifactRef` resolves via the test `ArtifactResolver` stub;
   - estimated context after each compaction ≤ window − reserve;
   - final outcome equals the uncompacted baseline (outcome equality).

**Expected**: compacted mission completes 50+ iterations within budget with
identical outcome.

## Scenario 4 — pi_agent seed, zero stubs (US4 AC1, SC-004)

1. `grep -rn "placeholder\|TODO\|typedef AgentTool.*dynamic" lib/` → no
   matches.
2. Every file under `lib/src/` ported from pi_agent opens with the
   attribution header (contracts/support-assets.md).
3. `dart analyze` clean; `dart test` green; `dart publish --dry-run` succeeds
   (LICENSE/NOTICE present, pure-Dart pubspec, no Flutter deps).

**Expected**: zero stub code in the shipped package; attribution complete.

## Edge cases verified by the suite

| Case | Test | Expected |
|---|---|---|
| Corrupt JSONL tail | `test/session_storage_test.dart` | loads salvaged prefix, returns `JsonlTear` with line number + reason |
| Branch deletion w/ shared ancestry | `test/session_test.dart` | sibling branch's ancestry intact; only leaf-only entries pruned |
| Compaction on one branch | `test/compaction_test.dart` | sibling branch ancestry unchanged (I2) |
| Compaction mid-batch | API shape | `compact()` invoked only from turn boundaries; no mid-batch calls possible from public API |

## Manual smoke (optional, no test harness)

```bash
dart run example/session_demo.dart   # forks, diverges, resumes, prints contexts
```

Expected output: two divergent context listings and a byte-identical
post-restart context — human-readable proof of Scenario 2.
