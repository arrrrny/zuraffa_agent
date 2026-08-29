---
feature: 069-mission-runner
verdict: PASS
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md
verified_at: HEAD of feat/spec-069-mission-runner # baseline master fec7889
behaviors: 11 # A1-A9, U1-U2
proven: 11
likely: 0
test_after: 0
no_test: 0
high_smells: 0
criteria_total: 8 # FR-001..FR-008
criteria_covered: 8
mutation_score: 100 # deliberate-mutant sampling: 5 of 5 killed (M1-M5)
mutants_survived: 0
suite: 925 passed, 0 failed, 2 skipped # baseline 915/2 at fec7889 + 10 new; skips are pre-existing KIMI_API_KEY integration tests
---

# Verification: MissionRunner (spec 069)

**Branch**: `feat/spec-069-mission-runner` | **Verified at**: branch HEAD
**Baseline**: master `fec7889` — 915 passed / 2 skipped, analyze clean

## Verdict: PASS

All 8 spec FRs implemented and traced to tests; genuine RED → GREEN; 5/5
deliberate mutants killed; both gates green with real counts.

## Cycle log

### RED (genuine)

Whole test file (`test/engine/mission_runner_test.dart`, 10 tests) written
FIRST against the missing `lib/src/engine/mission_runner.dart`:

```
test/engine/mission_runner_test.dart:499:17: Error: Undefined name 'MissionStatus'.
test/engine/mission_runner_test.dart:497:17: Error: Method not found: 'MissionResult'.
00:00 +0 -1: Some tests failed.  (loading failure — library absent)
```

### GREEN

Implemented `mission_runner.dart` (MissionStatus, MissionResult,
ToolCallPlanner, MissionRunner) → file green `+10: All tests passed!`.

**Finding #1 (test-authoring, resolved in-cycle)**: first green run failed
A3 with `planner.invocations` length 2 vs expected 1. Root cause: the TEST
was wrong, not the impl — FR-002 defines natural stop as "`finishReason ==
'sstop'` AND the planner produced no tool calls", i.e. the planner is
consulted after EVERY turn (its output participates in the stop decision),
including the natural-stop turn. Fixed the test expectation (turn 1:
'need tool'/2 msgs, turn 2: 'all done'/4 msgs) and aligned test-list U1
wording. Implementation untouched — it already matched the spec text.

**Finding #2 (process, self-reported)**: applying mutant M2, the first Edit
attempt removed the `ToolCallCompleted` arguments instead of the
`transcript.add` line, leaving the file syntactically broken. Detected
immediately by reading the edit diff; restored from the `cp` backup and
reapplied correctly before any test run. No false evidence was recorded.
(The 066 lesson holds: `cp` backups, never `git checkout` on uncommitted
work.)

### Mutations (deliberate, one at a time, cp-restored)

| id  | mutant | result | evidence |
| --- | ------ | ------ | -------- |
| M1  | `MissionStarted` emission dropped | KILLED | `+6 -4` — A1/A5/A8 event-sequence tests fail |
| M2  | tool-result transcript append skipped | KILLED | `+8 -2` — A3/A4 transcript-shape tests fail |
| M3  | turn-cap off-by-one (`>=` → `>`) | KILLED | `+9 -1` — A6: a 3rd turn is attempted past the policy cap (LLM script exhausted) |
| M4  | steering drain moved after `TurnStarted` | KILLED | `+9 -1` — A5: `SteeringInjected` must precede `TurnStarted` |
| M5  | `ToolCallCompleted.ok` hardcoded `true` | KILLED | `+9 -1` — A4: failed dispatch must report `ok: false` |

Each mutant was restored via `cp /tmp/mr_backup.dart` and the file re-run to
`+10: All tests passed!` before the next mutant. **5/5 killed — no
survivors.**

### Gates (actually run, at branch HEAD after final restore)

- `dart pub get` — clean
- `dart analyze --fatal-infos` — `No issues found!` (exit 0)
- `dart test` — **925 passed / 0 failed / 2 skipped** (baseline 915/2 at
  `fec7889` + 10 new; the 2 skips are the pre-existing `KIMI_API_KEY`
  integration tests, unrelated)

## FR traceability

| FR | status | evidence |
| -- | ------ | -------- |
| FR-001 ordered event emission + injectable clock | DONE | A1 (exact `[MissionStarted, TurnStarted, TurnCompleted, MissionCompleted]`), A5, A8; `DateTime.utc(2026,1,1)` stamps asserted |
| FR-002 natural completion | DONE | A1, A2 (status/summary/turnsUsed/transcript) |
| FR-003 tool dispatch round-trip | DONE | A3 (callId correlation, `isInternalMission: false`, tool-role append), A4 (failure path), U2 (unmodifiable planner view) |
| FR-004 steering drain | DONE | A5 (FIFO, before `TurnStarted`, user-role appends, `injectedAt` passthrough) |
| FR-005 budgets | DONE | A6 (`min` cap, terminal `'budgetExhausted'`, no backstop `StateError`), A7 (wall-clock via injected clock) |
| FR-006 provider failure | DONE | A8 (`ProviderError(providerName: 'kilo')`, `providerFailed`, terminal event still emitted, no `TurnCompleted`) |
| FR-007 MissionResult value semantics | DONE | A9 (==/hashCode/toString, element-wise transcript) |
| FR-008 gates | DONE | counts above |

## Notes / honest limitations

- `ToolDispatcher` has no production implementation in the repo yet — the
  runner codes against the interface and the tests inject fakes; production
  wiring is future tool-registry work (GAP-ANALYSIS row 3).
- `StopPolicy.repetitionThreshold` is carried but NOT enforced (needs
  `RepetitionTracker` wiring — declared out of scope).
- The `ToolCallPlanner` seam exists because `ChatCompletion` (spec 051) has
  no structured tool-call fields; a real LLM tool-call parser plugs in there
  when the completion VO grows them.
