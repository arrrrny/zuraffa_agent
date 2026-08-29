---
feature: 064-dart_io_free_gate
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
mutation_score: null # no high-risk path (no acceptance criteria; no auth/secrets/persistence/money) — mutation scoped out per rubric
mutants_survived: null
suite: 6 passed, 0 failed (file `test/data/providers/dart_io_free_gate/dart_io_free_gate_provider_test.dart`)
---

# TDD Verification: DartIoFreeGate static gate — spec 064

**Verdict: FAIL.** Every behavior is `TEST_AFTER`: the feature was already
implemented and merged before the test list existed, no `cycle-log.md` red was
recorded, and the list itself states *"No `RED` cycles were driven because the
implementation preceded the list"*. The 6 regression tests are reasonable
snapshots, but the discipline bar (red before green) was not met.

## Test-first evidence

| Behavior | Class      | Evidence                                                                                                   |
| -------- | ---------- | ---------------------------------------------------------------------------------------------------------- |
| U1       | TEST_AFTER | No red recorded. `cycle-log.md` holds only a baseline; the test asserts value equality across 4 fields.     |
| U2       | TEST_AFTER | No red recorded. Inequality-when-a-field-changes assertion.                                                |
| U3       | TEST_AFTER | No red recorded. `expect(provider, isA<DartIoFreeGateService>())` — a compile-time type guarantee (see #1). |
| U4       | TEST_AFTER | No red recorded. `current(NoParams)` returns the default snapshot assertion.                               |
| U5       | TEST_AFTER | No red recorded. Injected-value-object assertion.                                                          |
| U6       | TEST_AFTER | No red recorded. `count(NoParams) == 1` assertion.                                                         |

`git log` shows `DartIoFreeGateProvider` and its test were added together in a
single squashed commit (`39dd392`, "decompose epics into 24 sub-specs (041-064)
+ impl (#57)"), so per-cycle ordering is invisible and PROVEN cannot be claimed.
With no cycle-log red, all behaviors grade as TEST_AFTER (fail-closed).

## Findings

| #   | Severity | Finding                                                                                                                                                                                                                     | Evidence                                                          |
| --- | -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| 1   | LOW      | `U3` (`DartIoFreeGateProvider is a DartIoFreeGateService`) asserts `expect(provider, isA<DartIoFreeGateService>())` — a compile-time type guarantee, not a behavioral assertion. Green by definition. Mirrors spec 061; matches the repo's house pattern, so not a defect, but it proves nothing about runtime behavior. | `dart_io_free_gate_provider_test.dart` (the `is a` test)          |
| 2   | LOW      | Spec/code drift (reported, not followed): `spec.md`/`plan.md` describe the provider as a "stub throwing `UnimplementedError`", but the shipped `DartIoFreeGateProvider` returns a default snapshot and honors an injected value. The tests assert the shipped behavior, so traceability is sound, but the spec text is stale. | `spec.md`/`plan.md` vs `dart_io_free_gate_provider.dart`          |
| 3   | LOW      | The spec's headline deliverable — a *static gate that fails the build if the eval runtime imports `dart:io`* — is not implemented. What shipped is a plain-Dart value object plus a service/provider; no import-scanning or build-failing analyzer exists. The test-list records this as explicitly out of scope (`DartIoFreeGate` static analyzer), so the gap is documented, not a silent defect. The value object only *captures* `gateName`/`enforcedPaths`/`violationCount`. | `spec.md` Summary vs shipped `dart_io_free_gate.dart`; `test-list.md` §Out of scope |

No `HIGH` smells. The value-equality (`U1`/`U2`) and default-snapshot
(`U4`/`U5`) assertions check specific field values and are non-vacuous by
inspection. No weakened or skipped existing tests.

## Mutation results

No mutation run. The rubric scopes deliberate mutants to the highest-risk
behaviors (auth / secrets / persistence / money / acceptance-criterion paths).
Spec 064 has **no acceptance criteria** (`spec_criteria: 0`) and no such risk
path — it is a plain value object plus a provider stub. The value tests assert
specific defaults and field equality and are non-vacuous by inspection; running
deliberate mutants was judged out of scope for this spec.

## Traceability

`spec.md` declares `spec_criteria: 0`; the feature advances epic #6 §R6.5
(issue #7 US5) but has no numbered acceptance criteria. All 6 behaviors trace
to `R6.5` in the test list and each maps to a test that exists and runs
(confirmed green: 6 passed). Untested requirements: the spec's *static gate*
headline behavior is unimplemented (documented out of scope, finding #3). Tests
tracing to nothing: none.

## What was not audited

- No mutation tool exists in this repo (`mutation_test`/`glados` absent from the
  lockfile); deliberate mutants were scoped out for lack of a high-risk path.
- The full suite was not re-run end to end; only the single spec test file was
  executed (green, 6/0).
- The build-failing import-scan analyzer the feature name implies is not present
  in the shipped code, so there is nothing to test for that behavior.

## Remediation tasks

None. All findings are LOW and non-blocking; the only behavioral gap (the static
gate, finding #3) is already recorded as out-of-scope in the test list. No
acceptance-criterion or HIGH finding requires a remediation task.
