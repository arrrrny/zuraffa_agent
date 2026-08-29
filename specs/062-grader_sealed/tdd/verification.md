---
feature: 062-grader_sealed
verdict: FAIL
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md
verified_at: 01618f3
behaviors: 6
proven: 0
likely: 0
test_after: 6
no_test: 0
high_smells: 0
criteria_total: 0
criteria_covered: 0
mutation_score: null # no high-risk path (spec_criteria: 0; no auth/secrets/persistence/money) — mutation scoped out per rubric
mutants_survived: null
suite: 6 passed, 0 failed (file `test/data/providers/grader_sealed/grader_sealed_provider_test.dart`)
---

# TDD Verification: GraderSealed (spec 062)

**Verdict: FAIL.** All six behaviors are `TEST_AFTER`: the feature was
implemented and merged before the test list existed, no `cycle-log.md` red was
recorded, and the list states *"No RED cycles were driven because the
implementation preceded the list"*. The regression tests are reasonable, but the
red-before-green discipline was not followed.

## Test-first evidence

| Behavior | Class      | Evidence                                                                          |
| -------- | ---------- | --------------------------------------------------------------------------------- |
| U1       | TEST_AFTER | No red recorded; `test-list.md` declares the feature merged before the list.       |
| U2       | TEST_AFTER | No red recorded.                                                                  |
| U3       | TEST_AFTER | No red recorded. `isA` subtype check.                                             |
| U4       | TEST_AFTER | No red recorded. Default-snapshot assertion.                                      |
| U5       | TEST_AFTER | No red recorded. Injected-snapshot assertion.                                     |
| U6       | TEST_AFTER | No red recorded. `count() == 1` assertion.                                        |

`git log --follow` shows the test file landed in squashed commit `39dd392`
together with the source, so per-cycle ordering is not visible and PROVEN cannot
be claimed; with no cycle-log red, all behaviors grade TEST_AFTER (fail-closed).

## Findings

| #   | Severity | Finding                                                                                                                                              | Evidence                                   |
| --- | -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------ |
| 1   | LOW      | `U3` (`GraderSealedProvider is a GraderSealedService`) is an `isA` subtype check — a compile-time guarantee, green by definition, not a behavioral assertion. Matches the house pattern (mirrors spec 033). | `grader_sealed_provider_test.dart:27-30`   |
| 2   | LOW      | Spec/code drift (reported, not followed): `spec.md`/`plan.md` describe a `UnimplementedError` stub; the shipped `GraderSealedProvider` returns a default snapshot and honors an injected value. Tests assert shipped behavior; spec text is stale. | `spec.md:11` vs `grader_sealed_provider.dart` |
| 3   | LOW      | Spec/code drift on semantics: `spec.md` names a sealed union of `ExactGrader`/`SchemaGrader`/`ModelJudgeGrader` with a `grade()` method. The shipped code is a single 4-field value object with no `grade()` and no subtypes. The shipped behavior is tested; the spec's stated design is unimplemented (noted out-of-scope in the test list). | `spec.md:5-6` vs `grader_sealed.dart`      |

No `HIGH` smells. Value-equality (`U1`/`U2`) and default-snapshot (`U4`/`U5`)
assertions check specific fields and are non-vacuous by inspection. No weakened
or skipped existing tests.

## Mutation results

No mutation run. Spec 062 has `spec_criteria: 0` and no auth/secrets/
persistence/money/acceptance-criterion path, so deliberate mutants were scoped
out per the rubric. The value and default-snapshot tests assert specific values
and are non-vacuous by inspection.

## Traceability

`spec.md` declares `spec_criteria: 0`; the feature advances epic #6 §R6.3
(issue #7 US3) with no numbered acceptance criteria. All 6 behaviors trace to
`R6.3` and each maps to a test that exists and runs (confirmed green: 6/0).
Untested requirements: the spec's named `grade()` sealed-union design is
unimplemented; the test list records this as out-of-scope. Tests tracing to
nothing: none.

## What was not audited

- No mutation tool in this repo; deliberate mutants scoped out (no high-risk path).
- Full suite not re-run end to end; only the spec test file executed (green).
- Stale `UnimplementedError`-stub and `grade()` design descriptions in `spec.md`
  are noted as LOW findings, not remediated.
