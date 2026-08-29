---
feature: 054-health_snapshot
verdict: FAIL
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # short SHA audited
behaviors: 6
proven: 0
likely: 0
test_after: 6
no_test: 0
high_smells: 0
criteria_total: 0 # spec.md has no numbered acceptance criteria; advances epic #4 §R4.5 (issue #5 US4)
criteria_covered: 0
mutation_score: n/a # deliberate mutants only (no tool in lockfile); 1 behavior sampled, 0 survived
mutants_survived: 0
suite: per-file re-run green after mutant restore; planning-time baseline 909 passed, 2 skipped @ fec7889
---

# TDD Verification: HealthSnapshot (chain state) (spec 054)

**Verdict: FAIL.** All six behaviors are `TEST_AFTER`: the provider was merged
before the test list existed and no RED cycle was recorded.

## Test-first evidence

`tdd/cycle-log.md` has only a Baseline block (green at `fec7889`), no `red`.
Test list is explicitly test-after. History ordering not relied upon.

| Behavior | Class      | Evidence                                                          |
| -------- | ---------- | ----------------------------------------------------------------- |
| U1       | TEST_AFTER | No red logged; equality regression test over merged code          |
| U2       | TEST_AFTER | No red logged; inequality regression test over merged code        |
| U3       | TEST_AFTER | No red logged; `isA` seam test added after code                  |
| U4       | TEST_AFTER | No red logged; `current()` value-return test added after code    |
| U5       | TEST_AFTER | No red logged; `count()` test added after code                  |
| U6       | TEST_AFTER | No red logged; injected-value test added after code             |

## Findings

No `HIGH` smells. One `MED` weakness in U4:

| #   | Severity | Finding                                                                                                                    | Evidence                                    |
| --- | -------- | -------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------- |
| 1   | MED      | U4 asserts `capturedAt`, `healthyProviders`, and `trippedProviders` with `greaterThanOrEqualTo(0)`. These can never fail for a non-negative default and do not pin the real default values (`capturedAt 0`, `healthyProviders 1`, `trippedProviders 0`); only `id`/`chainId` are concretely pinned. Use exact equality for the documented defaults. | `health_snapshot_provider_test.dart:38-40` |

The test still pins `id == 'default'` and `chainId == 'chain-0'`, so it is not
vacuous overall; finding 1 is a decay risk.

## Mutation results

No mutation tool in the lockfile. One deliberate mutant on `current()` returning the
constructed default snapshot.

| Mutant                                            | Behavior | Survived | Judgment                                     |
| ------------------------------------------------- | -------- | -------- | -------------------------------------------- |
| `health_snapshot_provider.dart:21` `id:'default'` -> `'defaultX'` | U4 | No | Caught by U4; default id is pinned |

Mutant applied, single test failed, file restored via `git checkout`, test re-ran
green. No mutant left in the tree.

## Traceability

No numbered acceptance criteria in `spec.md` (`spec_criteria: 0`); advances epic
#4 §R4.5. All six behaviors trace to that epic and exercise the real
provider/value-object entry points.

Untested criteria: none. Tests tracing to nothing: none.

## What was not audited

- Per-provider open/closed/half-open breaker enumeration (specs 053/008) — out of scope.
- Git commit ordering not used as corroboration (list admits test-after).
- Full 909-test suite not re-run; only the sampled behavior's file.
- No acceptance / end-to-end loop for this `inside-out` value object.
