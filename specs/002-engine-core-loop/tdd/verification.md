---
feature: 002-engine-core-loop
verdict: FAIL
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # short SHA audited
behaviors: 10
proven: 5
likely: 0
test_after: 5
no_test: 0
high_smells: 0
criteria_total: 10
criteria_covered: 10 # all 10 Acceptance Scenarios exercised by a real passing test
mutation_score: 100 # scope: 7 of 10 behaviors sampled (those not sibling-credited), 0 survived
mutants_survived: 0 # all deliberate mutants killed
suite: 945 passed, 2 skipped (baseline from cycle log; targeted mutant tests re-run green)
---

# TDD Verification: Engine Core Loop (spec 002)

**Verdict: FAIL.** Five of ten acceptance behaviors (A1, A3, A5, A6, A10) carry no
red-cycle evidence in this feature's loop: A1/A6/A10 are satisfied by pre-existing
spec-069 sibling tests (no red was driven here), and A3/A5 passed on first run (their
cycle-log entries record a deliberate-mutant check in place of a red). The rubric
fails closed on any `TEST_AFTER` behavior, so the verdict is FAIL even though every
one of the ten behaviors is exercised by a real, passing, mutant-killed test, with no
HIGH smell, no untested criterion, and no surviving mutant. The failure is a
**discipline-evidence gap, not a coverage or quality gap** — the suite genuinely
proves the behaviors.

## Test-first evidence

| Behavior | Class      | Evidence                                                                                                                       |
| -------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------ |
| A1       | TEST_AFTER | Credited to `test/engine/mission_runner_test.dart` "tool dispatch round-trip…"; no red driven in 002's loop                    |
| A2       | PROVEN     | cycle A2 red recorded (`providerFailed` on overrunning fake); `b498e44` adds test + fixes fake; deliberate mutant killed       |
| A3       | TEST_AFTER | cycle A3 "passed first run (behavior already implemented)"; deliberate-mutant check substituted for red; mutant killed          |
| A4       | PROVEN     | cycle A4 red recorded (`getter 'thinking' isn't defined`); adds `ChatMessage.thinking`; deliberate mutant killed               |
| A5       | TEST_AFTER | cycle A5 "PASSED on its first run"; deliberate-mutant check substituted for red; mutant killed                                 |
| A6       | TEST_AFTER | Credited to `test/engine/mission_runner_test.dart` "steering queue drains at turn start…"; no red driven in 002's loop         |
| A7       | PROVEN     | cycle A7 red recorded (`method 'enqueue' isn't defined`); adds `MissionRunner.enqueue` + `continue` guard; mutant killed       |
| A8       | PROVEN     | cycle A8 red recorded (`budgetExhausted != maxTurnsExceeded`); adds `MissionStatus.maxTurnsExceeded`; mutant killed            |
| A9       | PROVEN     | cycle A9 red recorded (`No named parameter 'repetitionTracker'`); adds `RepetitionTrackerDatasource` seam; mutant killed        |
| A10      | TEST_AFTER | Credited to `test/engine/mission_runner_test.dart` "natural single-turn mission emits the full ordered event sequence"; no red  |

## Findings

| #   | Severity | Finding                                                                                                                                            | Evidence                                                          |
| --- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| 1   | LOW      | `tasks.md` leaves A4, A5, A7, A9 unchecked (`[ ]`) although `test-list.md` marks them DONE with passing tests and cycle-log entries. Documentation drift only — the tests exist and pass; the checkboxes were not ticked. | `tasks.md:14,15,17,19` vs `test-list.md` coverage table + cycle-log |

No HIGH *smell* (tautology / doubled subject / assertion-free / vacuous) was found.
Every sampled test asserts real values — exact event counts (A2), exhaustive
serialized event keys (A3), `thinking` field equality against a constant (A4/A5),
`turnsUsed` and typed `status.name` (A7/A8/A9), and `transcript` roles/content
(A1/A6/A10 in `mission_runner_test.dart`). A test that kills a deliberate mutant is,
by construction, not a tautology or vacuous assertion; all seven mutants below were
killed.

## Mutation results

No mutation tool is available; deliberate mutants were run on the seven non-sibling
behaviors (A1/A6/A10 are pre-covered by spec-069's own disciplined suite and were
read directly). Each mutant was restored exactly and the suite re-run green.

| Mutant                                                                   | Behavior | Survived | Judgment                                                                  |
| ------------------------------------------------------------------------ | -------- | -------- | ------------------------------------------------------------------------- |
| `mission_runner.dart` hard-capped `effectiveMaxTurns = 5`                | A2       | No       | A2 failed (`budgetExhausted` != `completed`); restored via `git checkout` |
| `mission_runner.dart` `final start = _clock()` → `DateTime.now()`       | A3       | No       | run 1 `MissionStarted` timestamp diverged → "stream diverged"; restored   |
| turn-cap branch reverted to `budgetExhausted`                            | A8       | No       | A8 failed (`budgetExhausted` != `maxTurnsExceeded`); restored             |
| `looping = true` → `looping = false` at the trip site                   | A9       | No       | A9 failed; restored                                                       |
| `thinking: completion.reasoning` → `thinking: null` (transcript)        | A4       | No       | A4 failed (`Expected: '…' Actual: <null>`); restored                      |
| `thinking: completion.reasoning` → `thinking: null` (turn-2 context)    | A5       | No       | A5 failed (`Expected: 'Turn one reasoning…' Actual: <null>`); restored   |
| removed `if (_queue != null && !_queue!.isEmpty) continue;` guard       | A7       | No       | A7 failed (`Expected: <2> Actual: <1>` turns); restored                  |

Scope: 7 of 10 behaviors sampled.

## Traceability

| Criterion (spec.md Acceptance Scenario) | Tests                                                            | End to end |
| --------------------------------------- | --------------------------------------------------------------- | ---------- |
| A1 (FR-001, FR-005)                      | `mission_runner_test.dart` "tool dispatch round-trip…"          | Yes        |
| A2 (FR-001)                             | `mission_runner_002_a2_test.dart`                               | Yes        |
| A3 (FR-001)                             | `mission_runner_002_a3_test.dart`                               | Yes        |
| A4 (FR-002)                             | `mission_runner_002_a4_test.dart`                               | Yes        |
| A5 (FR-002)                             | `mission_runner_002_a5_test.dart`                               | Yes        |
| A6 (FR-003)                             | `mission_runner_test.dart` "steering queue drains…"             | Yes        |
| A7 (FR-003)                             | `mission_runner_002_a7_test.dart`                               | Yes        |
| A8 (FR-004)                             | `mission_runner_002_a8_test.dart`                               | Yes        |
| A9 (FR-004)                             | `mission_runner_002_a9_test.dart`                               | Yes        |
| A10 (FR-005)                            | `mission_runner_test.dart` "natural single-turn… ordered events" | Yes       |

Untested criteria: none. Tests tracing to nothing: none — every claimed test exists,
runs, and asserts behavior. A1/A6/A10 trace to spec-069's suite (existing, real).

## What was not audited

- The full suite was not re-run end to end; only the seven mutant tests were executed
  (each re-run green after restore). Baseline green is taken from the cycle log
  (945 passed, 2 skipped).
- Inner-loop unit behaviors (engine-loop executor, stop policy, planner/steering
  queue, repetition detector) are deferred — `plan.md` is absent for this feature, so
  no `U1..` table exists. Those units have their own pre-existing tests (listed in
  `test-list.md`), which were not re-graded here.
- `dart analyze` was not re-run; the merged `master` baseline is assumed clean per
  the cycle log.
