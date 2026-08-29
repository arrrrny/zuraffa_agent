---
feature: 045-engine_loop
verdict: FAIL
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # short SHA audited
behaviors: 8
proven: 0
likely: 0
test_after: 8
no_test: 0
not_applicable: 0
high_smells: 1
criteria_total: 0
criteria_covered: 0
mutation_score: n/a # no mutation tool; deliberate mutants on highest-risk behavior only
mutants_survived: 1 # inside DONE behavior U7 — see Findings F1
suite: 8 passed, 0 failed (engine_loop provider + executor files, run this audit)
---

# TDD Verification: EngineLoop while-loop executor (spec 045)

**Verdict: FAIL — a deliberate mutant inside a `DONE` behavior survived.** `EngineLoopExecutor.runTurn`
guards the upper bound with `turnNumber > loop.maxTurns`; changing `>` to `>=` makes `turnNumber ==
maxTurns` throw (contradicting "exceeds maxTurns"), yet the existing tests only exercise `turnNumber`
4 (over cap) and 0 (non-positive). The suite stays green, so the inclusive edge `turnNumber ==
maxTurns` is unpinned and the `>` operator is untested. (The feature is also test-after — no RED
cycle was driven — but the surviving mutant is the decisive HIGH finding.)

## Test-first evidence

| Behavior | Class      | Evidence                                                                                |
| -------- | ---------- | --------------------------------------------------------------------------------------- |
| U1       | TEST_AFTER | no red recorded; implementation preceded the list (`tdd/cycle-log.md` baseline only)   |
| U2       | TEST_AFTER | no red recorded                                                                         |
| U3       | TEST_AFTER | no red recorded                                                                         |
| U4       | TEST_AFTER | no red recorded                                                                         |
| U5       | TEST_AFTER | no red recorded                                                                         |
| U6       | TEST_AFTER | no red recorded                                                                         |
| U7       | TEST_AFTER | no red recorded; **also unpinned at the inclusive boundary (see F1)**                  |
| U8       | TEST_AFTER | no red recorded                                                                         |

## Findings

| #   | Severity | Finding                                                                                                                  | Evidence                                                                  |
| --- | -------- | ------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------- |
| 1   | HIGH     | Surviving mutant in U7: `turnNumber > loop.maxTurns` → `>=` is not caught; the suite stays green, so the inclusive upper bound (`turnNumber == maxTurns` must NOT throw) is untested | `lib/src/data/providers/engine_loop/engine_loop_executor.dart:34`; mutant run this audit: `engine_loop_executor_test.dart` 3/3 passed |
| 2   | MED      | Entire feature is test-after; no RED cycle, test-first discipline not demonstrated                                       | `tdd/cycle-log.md` (baseline only, no reds)                               |

F1 detail: the test-list's own "Invariants" section admits "the exact equality boundary
(`turnNumber == maxTurns`) are not separately asserted — only the over-cap and non-positive cases
are." The mutant `>`→`>=` confirmed it: `dart test .../engine_loop_executor_test.dart` reported
`+3: All tests passed!` after the change, and `git checkout` restored the source exactly.

## Mutation results

No mutation tool configured. Deliberate hand-mutants, one at a time, restored exactly.

| Mutant                                          | Behavior | Survived | Judgment                                                                 |
| ----------------------------------------------- | -------- | -------- | ----------------------------------------------------------------------- |
| `turnNumber > loop.maxTurns` → `>=`             | U7       | **Yes**  | +3 passed; `turnNumber == maxTurns` now throws contrary to "exceeds"  |
| (lower bound `turnNumber < 1` → `<=`, not run)  | U8       | n/a      | not sampled                                                             |

1 survivor inside `DONE` behavior U7 → HIGH per rubric.

## Traceability

| Requirement | Tests                                                                       | End to end |
| ----------- | --------------------------------------------------------------------------- | ---------- |
| R2 (value equality + provider + runTurn guards) | U1..U5 (provider), U6..U8 (`engine_loop_executor_test.dart`) | Yes (executor public API) |

Untested boundaries: `turnNumber == maxTurns` inclusive edge (U7) — see F1. Tests tracing to
nothing: none.

## What was not audited

- Test-first evidence entirely absent (test-after by design); grading fails closed on that too.
- Only the upper-bound comparison was mutated; lower bound and the LLM delegation happy path were
  not mutated (happy path U6 is exercised, so a delegation-drop mutant would likely be caught).
- Coverage not formatted.
