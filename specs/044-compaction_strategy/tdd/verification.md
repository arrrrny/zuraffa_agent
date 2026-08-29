---
feature: 044-compaction_strategy
verdict: FAIL
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # short SHA audited
behaviors: 6
proven: 0
likely: 0
test_after: 6
no_test: 0
not_applicable: 0
high_smells: 0
criteria_total: 0
criteria_covered: 0
mutation_score: n/a # no mutation tool; mutants not sampled this audit
mutants_survived: n/a
suite: 6 passed, 0 failed (compaction_strategy_provider_test.dart, run this audit)
---

# TDD Verification: CompactionStrategy selective retain/summarize (spec 044)

**Verdict: FAIL.** All six behaviors (U1–U6) are recorded **test-after**: the feature was
implemented and merged before this TDD list existed, no `RED` cycle was driven, and the cycle log
records only a green baseline. Per the rubric a `TEST_AFTER` behavior fails the test-first gate.
The regression tests are real (value equality + clean-arch layering) but test-first discipline is
not demonstrated.

## Test-first evidence

| Behavior | Class      | Evidence                                                                         |
| -------- | ---------- | -------------------------------------------------------------------------------- |
| U1       | TEST_AFTER | no red recorded; implementation preceded the list                               |
| U2       | TEST_AFTER | no red recorded                                                                  |
| U3       | TEST_AFTER | no red recorded                                                                  |
| U4       | TEST_AFTER | no red recorded                                                                  |
| U5       | TEST_AFTER | no red recorded                                                                  |
| U6       | TEST_AFTER | no red recorded                                                                  |

`specs/044-compaction_strategy/tdd/cycle-log.md` contains only a baseline entry; the test-list
states "No `RED` cycles were driven because the implementation preceded the list."

## Findings

| #   | Severity | Finding                                                                     | Evidence                                     |
| --- | -------- | --------------------------------------------------------------------------- | -------------------------------------------- |
| 1   | MED      | Entire feature is test-after; no RED cycle, test-first discipline absent    | `tdd/cycle-log.md` (baseline only, no reds) |

No `HIGH` smells. The actual retain/summarize *policy* (selective compaction of a transcript) named
in the spec is not implemented or tested (engine feature, out of scope); only the strategy snapshot
value object + default-returning provider are covered. The "Discrepancies" note records the
spec-vs-code drift (provider returns a default, not `UnimplementedError`) as data, not instructions.

## Mutation results

Not sampled this audit. Recorded as unscoped.

## Traceability

| Requirement | Tests                                    | End to end |
| ----------- | ---------------------------------------- | ---------- |
| R1 (value equality + clean-arch) | U1..U6 (`compaction_strategy_provider_test.dart`) | Yes |

Untested requirements: none (the retain/summarize transformation is explicitly out of scope).
Tests tracing to nothing: none.

## What was not audited

- Test-first evidence entirely absent (test-after by design); grading fails closed.
- Mutation testing not performed.
- Coverage not formatted.
