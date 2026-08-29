---
feature: 084-llm-retry-backoff
verdict: PASS
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md
verified_at: 084-llm-retry-backoff (working tree, pre-commit)
behaviors: 10
proven: 10
likely: 0
test_after: 0
no_test: 0
high_smells: 0
criteria_total: 8
criteria_covered: 8
mutation_score: 100 # deliberate sample: 4/4 highest-risk behaviors killed
mutants_survived: 0
suite: 8 passed, 0 failed # test/llm/retry_084_test.dart at branch HEAD
---

# TDD Verification: LLM Client Retry & Backoff (spec 084)

**Verdict: PASS.** Every behavior is `PROVEN` (two-stage red evidence in
`tdd/cycle-log.md`: missing members, then three failing assertions), no
HIGH smells, every acceptance criterion covered, all 4 deliberate mutants
killed, and the spec-007 suite passes unmodified.

## Test-first evidence

| Behavior | Class  | Evidence |
| -------- | ------ | -------- |
| A1 transient failure survived or clearly terminal | PROVEN | T1 recovery green; T2/T3/T5 red → green (cycle 1) |
| A2 gates | PROVEN | `dart analyze` 3 issues = master baseline; `dart test` 1081/2/0 (baseline 1073/2 + 8) |
| U1 network exhaustion terminal + attempts | PROVEN | cycle 1 step 2: T2 failing → green; M3 kill |
| U2 HTTP exhaustion attempts + naming | PROVEN | cycle 1 step 2: T3 failing → green; M2 kill |
| U3 unclamped Retry-After (7200s) | PROVEN | cycle 1 step 2: T5 failing (slept 3600000) → green; M1/M4 kills |
| U4 network recovery pin | PROVEN | pin by design (untested path on master); M4 guards the sleep policy |
| U5 90s directive over cap | PROVEN | pin by design; M4 kill |
| U6 negative directive → 0 | PROVEN | pin by design; M4 kill |
| U7 stream parity | PROVEN | pin by design (untested path on master) |
| U8 cross-run determinism | PROVEN | pin by design; literal sequence `[133, 250, 250, 250]` |

## Findings

No HIGH smells. Expected sleep sequences and attempt counts are literal
values, never recomputed with the production formula. The exhausted-error
assertions use `having(...)` chains on specific fields (`attempts`,
`statusCode`, `body`, `cause`), not "did not throw". The one test-side
arithmetic slip found during RED (T9's expected sequence) was fixed in the
test BEFORE any production edit and is documented in the cycle log — the
production change was never adjusted to satisfy a wrong expectation.

Behavior-change note (intended, spec'd): directives longer than 3600s now
sleep their full length instead of one hour — this is the fix FR-003
exists for, flagged in the PR body for reviewers.

## Mutation results

| Mutant | Behavior | Survived | Judgment |
| ------ | -------- | -------- | -------- |
| M1 3600s ceiling reinstated | U3 | No | Killed: T5 — 3600000 ≠ 7200000 |
| M2 HTTP attempts dropped | U2 | No | Killed: T3 — attempts stayed 1 |
| M3 bare rethrow restored | U1 | No | Killed: T2 — terminal error lost the count |
| M4 Retry-After ignored | U3, U5, U6 | No | Killed: T5 + T6 + T7 (3 failures) |

Scope: 4 of 10 behaviors sampled (the highest-risk: the clamp, both
annotation paths, the directive handling). Not exhaustive; each mutant was
cp-restored and the suite re-verified green.

## Traceability

| Criterion | Tests | End to end |
| --------- | ----- | ---------- |
| FR-001 retryable set (429/5xx/network; 4xx immediate) | T1; existing U4/U5/U7 (spec-007, unmodified) | Yes |
| FR-002 exponential backoff + cap + maxAttempts | existing U8 (spec-007); T9 literals | Yes |
| FR-003 Retry-After unclamped | T5, T6, T7 + M1, M4 | Yes |
| FR-004 network errors retried | T1, T2 | Yes |
| FR-005 attempt-annotated final errors | T2, T3 + M2, M3 | Yes |
| FR-006 deterministic injected clock | T9 | Yes |
| FR-007 stream parity | T8 | Yes |
| FR-008 gates | A2 | Yes |

## Gates

- `dart analyze` — 3 issues, byte-identical set to master baseline. No new
  issues introduced.
- `dart test` — **1081 passed / 2 skipped / 0 failed** (baseline 1073/2 +
  8 new; spec-007 `retry_test.dart` 6/6 green unmodified; whole
  `test/llm/` 105/105).
