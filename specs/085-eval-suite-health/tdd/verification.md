---
feature: 085-eval-suite-health
verdict: PASS
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md
verified_at: 085-eval-suite-health (working tree, pre-commit)
behaviors: 10
proven: 10
likely: 0
test_after: 0
no_test: 0
high_smells: 0
criteria_total: 10
criteria_covered: 10
mutation_score: 100 # deliberate sample: 4/4 highest-risk behaviors killed
mutants_survived: 0
suite: 8 passed, 0 failed # test/eval/suite_gate_085_test.dart at branch HEAD
---

# TDD Verification: Eval Suite Health & Release Gate (spec 085)

**Verdict: PASS.** Every behavior is `PROVEN` (two-stage red evidence in
`tdd/cycle-log.md`: missing members, then three failing assertions), no
HIGH smells, every acceptance criterion covered, all 4 deliberate mutants
killed, and the spec-006 A4 suite passes unmodified.

## Test-first evidence

| Behavior | Class  | Evidence |
| -------- | ------ | -------- |
| A1 gate trustworthy in the corners | PROVEN | cycle 1: T1/T2/T3 red → green (fail-open fix, crash fix, veto fields) |
| A2 gates | PROVEN | `dart analyze` 3 issues = master baseline; `dart test` 1081/2/0 (baseline 1073/2 + 8) |
| U1 zero-task fail-closed | PROVEN | cycle 1 step 2: T1 failing (`0.0 >= 0.0` passed) → green; M2 kill |
| U2 zero-run veto, no crash | PROVEN | cycle 1 step 2: T2 failing (`ArgumentError`) → green; M3 kill |
| U3 machine-readable veto, suite order | PROVEN | cycle 1 step 2: T3 failing → green; M1/M4 kills |
| U4 all-missing pin | PROVEN | pin by design; M1/M4 kills |
| U5 `>=` boundary pin | PROVEN | pin by design; exact fixture (c:1 → 0.5), complements 006-A4 |
| U6 unbiased value pin | PROVEN | pin by design; `0.4` literal (1 - C(6,1)/C(10,1)) |
| U7 extra-ids-ignored pin | PROVEN | pin by design |
| U8 `c > n` throws pin | PROVEN | pin by design (contract honesty) |

## Findings

No HIGH smells. Expected values are literal arithmetic written from the
estimator's definition (e.g. pass@2 for n=4, c=1 is 1 - C(3,2)/C(4,2) =
0.5), never recomputed via `PassAtK.compute`. The veto assertions target
specific fields (`incomplete`, `incompleteTaskIds` ordering) rather than
report prose. The one fixture arithmetic slip found during RED (T5) was
fixed in the TEST before any production edit and is documented in the
cycle log.

Behavior-change notes (intended, spec'd, flagged in the PR): (1) a
zero-task suite at threshold 0.0 now FAILS (was: passed); (2)
`TaskSamples(n: 0)` now yields a veto (was: `ArgumentError` crash).

## Mutation results

| Mutant | Behavior | Survived | Judgment |
| ------ | -------- | -------- | -------- |
| M1 veto dropped from `passed` | U3, U4 | No | Killed: T3 + T4 (3 failures total) |
| M2 empty-suite guard removed | U1 | No | Killed: T1 — zero-task suite passes again |
| M3 zero-run branch removed | U2, U3 | No | Killed: T2 + T3 — the crash returns |
| M4 veto ids never recorded | U2, U3, U4 | No | Killed: T2 + T3 + T4 (3 failures) |

Scope: 4 of 10 behaviors sampled (the highest-risk: the veto wiring, the
fail-closed guard, the zero-run path). Not exhaustive; each mutant was
cp-restored and the suite re-verified green.

## Traceability

| Criterion | Tests | End to end |
| --------- | ----- | ---------- |
| FR-001 unbiased per-task pass@k | U6 (T6); spec-006 A4 / spec-037 (unmodified) | Yes |
| FR-002 mean over declared tasks | U6, U7 (T6, T7) | Yes |
| FR-003 `>=` boundary | U5 (T5); spec-006 A4 (unmodified) | Yes |
| FR-004 missing task veto | U4 (T4); spec-006 A4 (unmodified) | Yes |
| FR-005 zero-run veto, no crash | U2 (T2) + M3 | Yes |
| FR-006 machine-readable veto | U3 (T3) + M1, M4 | Yes |
| FR-007 zero-task fail-closed | U1 (T1) + M2 | Yes |
| FR-008 all-incomplete | U4 (T4) | Yes |
| FR-009 pure/deterministic; `c > n` throws | U8 (T8); whole file | Yes |
| FR-010 gates | A2 | Yes |

## Gates

- `dart analyze` — 3 issues, byte-identical set to master baseline. No new
  issues introduced.
- `dart test` — **1081 passed / 2 skipped / 0 failed** (baseline 1073/2 +
  8 new; spec-006 `suite_gate_006_a4_test.dart` green unmodified; whole
  `test/eval/` 14/14).
