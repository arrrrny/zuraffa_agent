---
feature: 27-stop_policy-datasource-pair
verdict: PASS_WITH_GAPS
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # short SHA audited
behaviors: 18 # A1-A6 (6) + U1-U12 (12); U4 and U10 are NOT_APPLICABLE baselines (compile parity) and excluded from proven/test_after counts
proven: 16
likely: 0
test_after: 0
no_test: 0
high_smells: 0
criteria_total: 6 # test-list spec_criteria: 6 (AC US1-1..2, US2-1..2, US3-1..2)
criteria_covered: 6
mutation_score: 100 # deliberate-mutant sample this audit: 2 of 2 killed (scope: changed source files only; no mutation tool in lockfile)
mutants_survived: 0
suite: 20 passed (entity 3 + datasource 4 + repository 6 + provider 7) at HEAD 01618f3; full suite green
---

# TDD Verification: StopPolicy datasource + mock pair

**Verdict: PASS_WITH_GAPS.** Test-first discipline is corroborated by git history
(real test-before-impl commits `a57f81f`→`515a01b`, `e978786`→`3a44bab`,
`8de8f41`→`c1e0089`→`541414a`, `34da014`→`8e170bf`) and by a `cycle-log.md`
that records a red per cycle, including a decisive design-correction red in cycle
4. No HIGH smells and every acceptance criterion has an end-to-end test through
the datasource/provider chain; the sampled deliberate mutants were killed. Gaps:
coverage not measured; `cycle-log.md` cites SHAs that do not resolve at HEAD
(finding #1).

## Test-first evidence

| Behavior | Class     | Evidence |
| -------- | --------- | -------- |
| A1 fresh chain returns default | PROVEN | red recorded (cycle 4); `34da014` precedes `8e170bf` |
| A2 seeded policy served by current(NoParams) | PROVEN | red recorded (cycle 4) |
| A3 update read-after-write | PROVEN | red recorded (cycle 2); `e978786` precedes `3a44bab` |
| A4 reset restores default through chain | PROVEN | red recorded (cycle 4) |
| A5 reads served through datasource seam | PROVEN | red recorded (cycle 4) |
| A6 unknown id raises StateError | PROVEN | red recorded (cycle 3); `8de8f41` precedes `c1e0089` |
| U1 defaultPolicy values | PROVEN | red recorded (cycle 1); `a57f81f` precedes `515a01b` |
| U2 value equality | PROVEN | red recorded (cycle 1) |
| U3 hashCode parity | PROVEN | red recorded (cycle 1) |
| U4 mock compile parity | NOT_APPLICABLE | baseline `isA` check |
| U5 fresh mock current() = default | PROVEN | red recorded (cycle 2) |
| U6 update fully replaces (old id unreachable) | PROVEN | red recorded (cycle 2) |
| U7 reset restores default (mock) | PROVEN | red recorded (cycle 2) |
| U8 RepositoryImpl is StopPolicyRepository | PROVEN | red recorded (cycle 3) |
| U9 delegate to datasource | PROVEN | red recorded (cycle 3) |
| U10 Provider is StopPolicyService | NOT_APPLICABLE | baseline `isA` check |
| U11 parameterless ctor compiles | PROVEN | red recorded (cycle 4) |
| U12 defaultPolicy(NoParams) constant | PROVEN | red recorded (cycle 4) |

## Findings

| #   | Severity | Finding | Evidence |
| --- | -------- | ------- | -------- |
| 1   | MED | `cycle-log.md` cites commit SHAs (`5c1d795`, `3e759c2`, `b54244b`, `658a3d0`) that **do not exist** at HEAD. Real commits (`a57f81f`, `515a01b`, `e978786`, `3a44bab`, `8de8f41`, `c1e0089`, `541414a`, `34da014`, `8e170bf`) confirm test-before-impl ordering and the reds, so test-first is corroborated — but the cycle-log as written is not reproducible. | `specs/27-*/tdd/cycle-log.md` vs `git log` |
| 2   | MED | `U11` (`test/data/providers/stop_policy/stop_policy_provider_test.dart:27-30`) asserts only `expect(provider, isNotNull)` — a vacuous assertion (non-null where the behavior is "default wiring"). The compile-time contract (parameterless constructor exists) is real and A1 independently verifies the runtime default-wiring, so the risk is contained, but the test's runtime body proves nothing of its own. Consider asserting `provider.current(NoParams())` equals `StopPolicy.defaultPolicy` (or removing U11 as redundant with A1). | `test/data/providers/stop_policy/stop_policy_provider_test.dart:27-30` |
| 3   | LOW | `tasks.md` leaves every task `[ ]` while `test-list.md` marks all behaviors DONE — artifacts disagree on completion status (not the rubric's HIGH `[X]` rule). | `specs/27-*/tasks.md` vs `test-list.md` |

No HIGH smells. The cycle-4 design correction (provider binds to the datasource's
id-less `current()` rather than the id-keyed repository) is recorded in the
cycle-log and amended spec/plan in the same commit; no test was weakened.

## Mutation results

No mutation tool is installed. This audit sampled the two highest-risk mutants
(persistence reset = data loss; id-mismatch guard = silent substitution), each
restored exactly and the suite re-run green afterwards:

| Mutant | Behavior | Survived | Judgment |
| ------ | -------- | -------- | -------- |
| `reset()` no-op (drop `_policy = StopPolicy.defaultPolicy`) (`stop_policy_mock_datasource.dart:38`) | U7, A4 | No | caught — U7 expects `current()` == default after reset; A4 fails through the provider chain |
| `getCurrent` drops id-mismatch `StateError` guard (`stop_policy_repository_impl.dart:30`) | A6 | No | caught — A6 expects `throwsA<StateError>` for unknown id |

Both killed. Additional mutants documented in the prior `verification.md`
(default-constant drift, no-op update, seam-bypass) were recorded killed but were
**not independently re-run** by this cold audit; this audit's 2 sampled mutants
confirm the reset and guard paths. Working tree verified clean and the targeted
suite re-ran green (20 passed) after restore.

## Traceability

| Criterion | Tests | End to end |
| --------- | ----- | ---------- |
| AC US1-1 default served by fresh chain | A1, U1 | Yes — real provider + datasource |
| AC US1-2 seeded policy served | A2 | Yes |
| AC US2-1 update read-after-write | A3, U6 | Yes |
| AC US2-2 reset restores default | A4, U7 | Yes |
| AC US3-1 reads through datasource seam | A5, U9 | Yes |
| AC US3-2 unknown id raises StateError | A6, U9 | Yes |
| SC-001 default constant | U1 | Yes |
| SC-002 entity parity | U2, U3 | Yes |
| SC-003 provider chain | A1, A2, A4, A5, U12 | Yes |
| SC-004 repository seam | A6, U8, U9 | Yes |
| SC-005 analyze + suite green | A3, A4 | Yes (gate) |

Untested criteria: none. Tests tracing to nothing: none (U4/U10 baselines are
deliberate compile-parity checks).

## What was not audited

- Coverage: `package:coverage` not installed; not measured.
- The cycle-log commit citations are stale/fabricated (finding #1) — test-first
  re-confirmed via `git log`.
- Stop-condition enforcement (turn-count comparison, outcome emission) lives in
  the engine loop (specs 002/046): out of scope.
- Hive/remote-backed datasource: interface contract only; out of scope.
