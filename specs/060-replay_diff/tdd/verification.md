---
feature: 060-replay_diff
verdict: FAIL
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # short SHA audited
behaviors: 6
proven: 0
likely: 0
test_after: 6
no_test: 0
high_smells: 0
criteria_total: 0 # spec.md has no numbered acceptance criteria; advances epic #6 §R6.1 (Eval Harness) issue #7 US1
criteria_covered: 0
mutation_score: n/a # deliberate mutants only (no tool in lockfile); 1 behavior sampled, 0 survived
mutants_survived: 0
suite: per-file re-run green after mutant restore; planning-time baseline 909 passed, 2 skipped @ b9ba15c
---

# TDD Verification: ReplayDiff input drift detection (spec 060)

**Verdict: FAIL.** All six behaviors are `TEST_AFTER`: the provider was merged
before the test list existed and no RED cycle was recorded.

## Test-first evidence

`tdd/cycle-log.md` has only a Baseline block (green at `b9ba15c`), no `red`.
Test list is explicitly test-after. History ordering not relied upon.

| Behavior | Class      | Evidence                                                          |
| -------- | ---------- | ----------------------------------------------------------------- |
| U1       | TEST_AFTER | No red logged; equality regression test over merged code          |
| U2       | TEST_AFTER | No red logged; inequality regression test over merged code        |
| U3       | TEST_AFTER | No red logged; `isA` seam test added after code                  |
| U4       | TEST_AFTER | No red logged; `current()` value-return test added after code    |
| U5       | TEST_AFTER | No red logged; injected-value test added after code             |
| U6       | TEST_AFTER | No red logged; `count()` test added after code                  |

## Findings

No `HIGH` smells. U4 (`replay_diff_provider_test.dart:32`) asserts
`id == 'default'`, `missionId == 'mission-0'`, `driftDetected == false` — concrete
value checks. U5 returns the injected object and pins `diffSummary == 'bytes differ'`.
Suite is clean. The test-list's own Discrepancies section already records that the
file holds 6 tests (2 equality + 4 clean-arch) versus the spec's stated 5, and lists
all of them, so the list is truthful here (no traceability gap).

| #   | Severity | Finding | Evidence |
| --- | -------- | ------- | -------- |
| —   | —        | None    | —        |

## Mutation results

No mutation tool in the lockfile. One deliberate mutant on `current()` returning the
constructed default snapshot.

| Mutant                                      | Behavior | Survived | Judgment                                     |
| ------------------------------------------- | -------- | -------- | -------------------------------------------- |
| `replay_diff_provider.dart:21` `id:'default'` -> `'defaultX'` | U4 | No | Caught by U4; default id is pinned |

Mutant applied, single test failed, file restored via `git checkout`, test re-ran
green. No mutant left in the tree.

## Traceability

No numbered acceptance criteria in `spec.md` (`spec_criteria: 0`); advances epic
#6 §R6.1. All six behaviors trace to that epic and exercise the real entry points.

Untested criteria: none. Tests tracing to nothing: none.

## What was not audited

- Engine-side / eval-harness consumption of the replay-diff snapshot — out of scope.
- Git commit ordering not used as corroboration (list admits test-after).
- Full 909-test suite not re-run; only the sampled behavior's file.
- No acceptance / end-to-end loop for this `inside-out` value object. The spec
  names byte-level "input drift detection" in prose, but the shipped value object
  only captures `driftDetected`/`diffSummary`; no detection algorithm is exercised
  (flagged in the test-list's Invariants, not a missing test for shipped code).
