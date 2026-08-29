---
feature: 053-fallback_chain
verdict: FAIL
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # short SHA audited
behaviors: 5
proven: 0
likely: 0
test_after: 5
no_test: 0
high_smells: 0
criteria_total: 0 # spec.md has no numbered acceptance criteria; advances epic #4 §R4.4 (issue #5 US3)
criteria_covered: 0
mutation_score: n/a # deliberate mutants only (no tool in lockfile); 1 behavior sampled, 0 survived
mutants_survived: 0
suite: per-file re-run green after mutant restore; planning-time baseline 909 passed, 2 skipped @ fec7889
---

# TDD Verification: FallbackChain (advance policy + state) (spec 053)

**Verdict: FAIL.** All five behaviors are `TEST_AFTER`: the provider was merged
before the test list existed and no RED cycle was recorded. The regression tests
assert concrete values, but the loop was test-after.

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

## Findings

No `HIGH` smells. One `MED` weakness worth recording for the next author:

| #   | Severity | Finding                                                                                          | Evidence                                  |
| --- | -------- | ------------------------------------------------------------------------------------------------ | ----------------------------------------- |
| 1   | MED      | U4 derives the upper bound of its range assertion from the returned object itself (`inInclusiveRange(0, chain.providerIds.length - 1)`). Because `currentProviderIndex` and `providerIds` both come from the same returned snapshot, a bug where the index is inconsistent with an external source of truth cannot be caught — the assertion is self-consistent by construction. Pin `currentProviderIndex` to its literal default (`0`) instead. | `fallback_chain_provider_test.dart:37` |

U4 still pins `chain.id == 'default'`, so the test is not vacuous overall; finding 1
is a decay risk, not a `HIGH`.

## Mutation results

No mutation tool in the lockfile. One deliberate mutant on `current()` returning the
constructed default chain snapshot.

| Mutant                                          | Behavior | Survived | Judgment                                     |
| ----------------------------------------------- | -------- | -------- | -------------------------------------------- |
| `fallback_chain_provider.dart:21` `id:'default'` -> `'defaultX'` | U4 | No | Caught by U4; default id is pinned |

Mutant applied, single test failed, file restored via `git checkout`, test re-ran
green. No mutant left in the tree.

## Traceability

No numbered acceptance criteria in `spec.md` (`spec_criteria: 0`); advances epic
#4 §R4.4. All five behaviors trace to that epic. Note the spec names an "advance
policy" + circuit breaker; those transitions live in spec 008 /
`test/domain/entities/fallback_chain_test.dart` (out of spec 053's plan) and are
not graded here.

Untested criteria: none. Tests tracing to nothing: none within spec 053.

## What was not audited

- The advance-policy state machine & breaker states (spec 008) — out of scope.
- Git commit ordering not used as corroboration (list admits test-after).
- Full 909-test suite not re-run; only the sampled behavior's file.
- No acceptance / end-to-end loop for this `inside-out` value object.
