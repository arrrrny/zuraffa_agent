---
feature: 006-eval-harness-golden
verdict: FAIL
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # short SHA audited
behaviors: 9
proven: 3
likely: 0
test_after: 6
no_test: 0
high_smells: 5
criteria_total: 9
criteria_covered: 4 # A1,A3,A4,A8 have a real passing test; A2,A5,A6,A7,A9 do not
mutation_score: 100 # scope: 3 genuine cycles (A1,A4,A8), 0 survived
mutants_survived: 0 # all deliberate mutants killed
suite: 952 passed, 2 skipped (baseline from A8 cycle log; targeted mutant tests re-run green)
---

# TDD Verification: Eval Harness — Golden Missions, Record/Replay, pass@k (spec 006)

**Verdict: FAIL.** Five acceptance criteria (A2, A5, A6, A7, A9) are exercised by **no
test at all**, and their `traces` in `test-list.md` point at provider tests that verify
only the **value-equality / clean-arch layer** of the relevant entity — not the acceptance
behavior. Three behaviors (A1, A4, A8) are genuine red→green cycles with killed mutants,
so the cassette-replay, gate-decision, and suite-runner paths are well tested; the gap is
the grader matrix, replay-drift detection, and the `dart:io` scan, whose cited tests are
entity-only and whose execution logic is not present in `lib` (the service interfaces
expose only `current()`/`count()`, no `grade()`/`scan()`). A3 (pass@k estimator) is
behaviorally covered by `PassAtK.compute` tests, but mis-cited.

## Test-first evidence

| Behavior | Class      | Evidence                                                                                              |
| -------- | ---------- | ----------------------------------------------------------------------------------------------------- |
| A1       | PROVEN     | cycle A1 red (missing replay client); added `cassette_replay_llm_client.dart`; deliberate mutant killed |
| A2       | TEST_AFTER | Credited to `replay_diff_provider_test.dart`; entity/clean-arch only — no drift-detection execution test |
| A3       | TEST_AFTER | Credited to `pass_at_k_provider_test.dart`; `PassAtK.compute` IS behaviorally tested there (formula/monotonicity) |
| A4       | PROVEN     | cycle A4 red (`SuiteGate` undefined); added `suite_gate.dart`; boundary + missing-samples mutants killed |
| A5       | TEST_AFTER | Credited to `grader_sealed_provider_test.dart`; entity/clean-arch only — no exact-grader execution test |
| A6       | TEST_AFTER | Credited to `grader_sealed_provider_test.dart`; entity/clean-arch only — no schema-grader execution test |
| A7       | TEST_AFTER | Credited to `grader_sealed_provider_test.dart`; entity/clean-arch only — no model-judge execution test |
| A8       | PROVEN     | cycle A8 red (test wiring); real pass/fail cohort driven; deliberate `passed = false` mutant killed     |
| A9       | TEST_AFTER | Credited to `dart_io_free_gate_provider_test.dart`; entity/clean-arch only — no package-scan test       |

## Findings

| #   | Severity | Finding                                                                                                                                                          | Evidence                                                                                              |
| --- | -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| 1   | HIGH     | A2 (replay input-drift reports a mismatch loudly) is marked DONE but exercised by **no test**. The cited `replay_diff_provider_test.dart` only tests `ReplayDiff` value equality; `ReplayDiffService` exposes only `current()`/`count()`, no detection. Acceptance criterion untested (and the detection logic is not implemented). | `test/data/providers/replay_diff/replay_diff_provider_test.dart:11-40`; `lib/src/domain/services/replay_diff_service.dart` (interface only) |
| 2   | HIGH     | A5 (exact grader decides by byte-equality) is marked DONE but exercised by **no test**. The cited `grader_sealed_provider_test.dart` is entity/clean-arch only; `GraderSealed` has no `grade()` method and no grader-execution test exists. Acceptance criterion untested (logic not implemented). | `test/data/providers/grader_sealed/grader_sealed_provider_test.dart:11-45`; `grep grade(` across `test/**` returns nothing |
| 3   | HIGH     | A6 (schema grader decides by JSON-Schema validity) is marked DONE but exercised by **no test**. Same entity-only cited test; no schema-grader execution test exists. Acceptance criterion untested (logic not implemented). | `test/data/providers/grader_sealed/grader_sealed_provider_test.dart:11-45`; no `schema` grader test in `test/**` |
| 4   | HIGH     | A7 (model-judge grader decides by parsed verdict; judge replays deterministically) is marked DONE but exercised by **no test**. Same entity-only cited test; no judge-grader execution test exists. Acceptance criterion untested (logic not implemented). | `test/data/providers/grader_sealed/grader_sealed_provider_test.dart:11-45`; no `judge`/`verdict` grader test in `test/**` |
| 5   | HIGH     | A9 (eval runtime package scanned has no `dart:io` imports) is marked DONE but exercised by **no test**. The cited `dart_io_free_gate_provider_test.dart` is entity/clean-arch only; `DartIoFreeGateService` exposes only `current()`/`count()`, no scan. Acceptance criterion untested (scan logic not implemented). | `test/data/providers/dart_io_free_gate/dart_io_free_gate_provider_test.dart:11-45`; `lib/src/domain/services/dart_io_free_gate_service.dart` (interface only) |
| 6   | MED      | A3 (pass@k scores match the analytic value) is mis-cited to the entity test; the `PassAtK.compute` estimator IS behaviorally tested (input validation, textbook formula, monotonicity). Re-point the trace. | `test/data/providers/pass_at_k/pass_at_k_provider_test.dart:29+` (real estimator tests) |

No HIGH *test smell* (tautology / doubled subject / assertion-free) was found in the
tests that exist. The three genuine cycles (A1, A4, A8) contain real, value-bearing
assertions and killed mutants; the failures here are missing tests for the grader matrix,
replay-drift detection, and `dart:io` scan (F1–F5), not weak assertions.

## Mutation results

| Mutant                                                              | Behavior | Survived | Judgment                                                          |
| ------------------------------------------------------------------ | -------- | -------- | ----------------------------------------------------------------- |
| `_completions[_cursor++]` → `_completions[0]` (serve first forever) | A1       | No       | A1 failed (`Expected: <2> Actual: <0>` consumed); restored        |
| `score >= suite.gateThreshold` → `score >`                          | A4       | No       | at-threshold case failed (`Expected: true`); restored             |
| `passed = score >= … && !incomplete` → `passed = false`             | A8       | No       | passing-cohort case failed (`Expected: true`); restored           |

Scope: 3 of 9 behaviors mutated (A1, A4, A8). Mutants survived: 0.

## Traceability

| Criterion | Tests (cited → real)                                                                 | End to end |
| --------- | ------------------------------------------------------------------------------------ | ---------- |
| A1        | `cassette_replay_006_a1_test.dart` (real, mutant-killed)                             | Yes        |
| A2        | cited `replay_diff_provider_test.dart` → **no drift-detection test anywhere**         | **No** (F1) |
| A3        | cited entity test → `pass_at_k_provider_test.dart` (`PassAtK.compute`, real)          | Yes        |
| A4        | `suite_gate_006_a4_test.dart` (real, mutant-killed)                                 | Yes        |
| A5        | cited `grader_sealed_provider_test.dart` → **no exact-grader test anywhere**         | **No** (F2) |
| A6        | cited `grader_sealed_provider_test.dart` → **no schema-grader test anywhere**         | **No** (F3) |
| A7        | cited `grader_sealed_provider_test.dart` → **no judge-grader test anywhere**          | **No** (F4) |
| A8        | `suite_runner_006_a8_test.dart` (real, mutant-killed)                               | Yes        |
| A9        | cited `dart_io_free_gate_provider_test.dart` → **no package-scan test anywhere**     | **No** (F5) |

Untested criteria: A2, A5, A6, A7, A9 (no test exercises the real entry point). Tests
tracing to nothing: none — but five `traces` (A2, A5, A6, A7, A9) point at tests that do
not test the behavior they claim (the rubric's "list is lying about coverage" condition).

## What was not audited

- The full suite was not re-run end to end; only the A1/A4/A8 mutant tests were executed
  (re-run green after restore). Baseline green is taken from the A8 cycle log (952 passed, 2 skipped).
- `grader_sealed` / `replay_diff` / `dart_io_free_gate` cited tests were read in full; their
  execution logic (if any) was not searched exhaustively in `lib` beyond the service interfaces.
- Inner-loop unit behaviors are deferred (`plan.md` absent for this feature).
- `dart analyze` was not re-run; the merged `master` baseline is assumed clean.
