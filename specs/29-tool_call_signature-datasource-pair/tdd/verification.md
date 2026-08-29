---
feature: 29-tool_call_signature-datasource-pair
verdict: PASS_WITH_GAPS
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # short SHA audited
behaviors: 16 # A1-A7 (7) + U1-U9 (9); U7 is NOT_APPLICABLE baseline (compile parity) and excluded from proven/test_after counts
proven: 15
likely: 0
test_after: 0
no_test: 0
high_smells: 0
criteria_total: 7 # test-list spec_criteria: 7 (AC US1-1..2, US2-1..3, US3-1..2)
criteria_covered: 7
mutation_score: 100 # deliberate-mutant sample this audit: 1 of 1 killed (scope: changed source files only; no mutation tool in lockfile)
mutants_survived: 0
suite: 14 passed (entity 6 + datasource 8) at HEAD 01618f3; full suite green
---

# TDD Verification: ToolCallSignature datasource + mock pair

**Verdict: PASS_WITH_GAPS.** Test-first discipline is corroborated by git history
(real test-before-impl commits `60b8b6e`→`31f020d`, `f769b74`→`f90fc23`→`7925ed5`)
and by a `cycle-log.md` that records a red per cycle (cycle 2/3 share one
test-first commit with two staged green commits, but the intermediate red is
recorded). No HIGH smells and every acceptance criterion has an end-to-end test
through the datasource public API; the sampled deliberate mutant was killed.
Gaps: coverage not measured; `cycle-log.md` cites SHAs that do not resolve at
HEAD (finding #1).

## Test-first evidence

| Behavior | Class     | Evidence |
| -------- | --------- | -------- |
| A1 capture→lookup round-trip | PROVEN | red recorded (cycle 2); `f769b74` precedes `f90fc23` |
| A2 miss reports null | PROVEN | red recorded (cycle 2) |
| A3 equal content ⇒ equal identity | PROVEN | red recorded (cycle 1); `60b8b6e` precedes `31f020d` |
| A4 differing component ⇒ different identity | PROVEN | red recorded (cycle 1) |
| A5 idempotent capture | PROVEN | red recorded (cycle 3); `UnimplementedError` red preserved |
| A6 count reflects distinct captures | PROVEN | red recorded (cycle 3) |
| A7 reset clears store | PROVEN | red recorded (cycle 3) |
| U1 equal ⇒ equal + hashCode | PROVEN | red recorded (cycle 1) |
| U2 differing ⇒ unequal | PROVEN | red recorded (cycle 1) |
| U3 key format | PROVEN | red recorded (cycle 1) |
| U4 version defaults to 1 | PROVEN | red recorded (cycle 1) |
| U5 legacy id construction compiles | PROVEN | red recorded (cycle 1) |
| U6 equality ignores legacy id | PROVEN | red recorded (cycle 1) |
| U7 mock compile parity | NOT_APPLICABLE | baseline `isA` check |
| U8 lookup null on miss | PROVEN | red recorded (cycle 2) |
| U9 empty toolName/argHash valid keys | PROVEN | red recorded (cycle 2) |

## Findings

| #   | Severity | Finding | Evidence |
| --- | -------- | ------- | -------- |
| 1   | MED | `cycle-log.md` cites commit SHAs (`7a6a9bd`, `4547b6a`) that **do not exist** at HEAD. Real commits (`60b8b6e`, `31f020d`, `f769b74`, `f90fc23`, `7925ed5`) confirm test-before-impl ordering and the reds, so test-first is corroborated — but the cycle-log as written is not reproducible. | `specs/29-*/tdd/cycle-log.md` vs `git log` |
| 2   | LOW | `A1` (`test/data/datasources/tool_call_signature/tool_call_signature_mock_datasource_test.dart:28`) asserts `expect(found, isNotNull)` immediately before `expect(found, equals(sig))` — the `isNotNull` is redundant (the equality assertion would fail on null). Cosmetic, not safety-affecting. | `test/.../tool_call_signature_mock_datasource_test.dart:23-30` |
| 3   | LOW | `tasks.md` leaves every task `[ ]` while `test-list.md` marks all behaviors DONE — artifacts disagree on completion status (not the rubric's HIGH `[X]` rule). | `specs/29-*/tasks.md` vs `test-list.md` |

No HIGH smells. No existing test was weakened or skipped (the 3 superseded
`UnimplementedError` stubs are documented drift remediation).

## Mutation results

No mutation tool is installed. This audit sampled the highest-risk mutant (the
capture→lookup round-trip / persistence read path), restored exactly and the
suite re-run green afterwards:

| Mutant | Behavior | Survived | Judgment |
| ------ | -------- | -------- | -------- |
| `lookup(key)` returns constant `null` (`tool_call_signature_mock_datasource.dart:33`) | A1 | No | caught — A1 expects `lookup(sig.key)` to return the captured signature |

Killed. Additional mutants documented in the prior `verification.md` (key drops
version, legacy id in equality, insertion-index keying, phantom miss) were
recorded killed but were **not independently re-run** by this cold audit; this
audit's 1 sampled mutant confirms the round-trip path. Working tree verified
clean and the targeted suite re-ran green (14 passed) after restore.

## Traceability

| Criterion | Tests | End to end |
| --------- | ----- | ---------- |
| AC US1-1 capture→lookup round-trip | A1 | Yes — real `ToolCallSignatureMockDatasource` |
| AC US1-2 miss reports null | A2, U8 | Yes |
| AC US2-1 equal content ⇒ equal identity | A3, U1 | Yes |
| AC US2-2 differing component ⇒ different identity | A4, U2 | Yes |
| AC US2-3 idempotent capture | A5 | Yes |
| AC US3-1 count reflects distinct captures | A6 | Yes |
| AC US3-2 reset clears store | A7 | Yes |
| SC-001 key derivation | U3 | Yes |
| SC-002 version default | U4 | Yes |
| SC-003 content equality | U1, U2 | Yes |
| SC-004..SC-006 entity parity / suite green | U1..U6, A1..A7 | Yes |

Untested criteria: none. Tests tracing to nothing: none (U7 baseline is a
deliberate compile-parity check).

## What was not audited

- Coverage: `package:coverage` not installed; not measured.
- The cycle-log commit citations are stale/fabricated (finding #1) — test-first
  re-confirmed via `git log`.
- Signature → result caching (spec 031) and argument-hash production: out of scope.
- Hive/remote-backed datasource: interface contract only; out of scope.
