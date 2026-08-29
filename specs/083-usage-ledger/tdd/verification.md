---
feature: 083-usage-ledger
verdict: PASS
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md
verified_at: 083-usage-ledger (working tree, pre-commit)
behaviors: 9
proven: 9
likely: 0
test_after: 0
no_test: 0
high_smells: 0
criteria_total: 8
criteria_covered: 8
mutation_score: 100 # deliberate sample: 4/4 highest-risk behaviors killed
mutants_survived: 0
suite: 7 passed, 0 failed # test/usage_ledger_083_test.dart at branch HEAD
---

# TDD Verification: Usage Ledger — token accounting projection (spec 083)

**Verdict: PASS.** Every behavior is `PROVEN` (two-stage red evidence in
`tdd/cycle-log.md`: missing members, then failing equality assertions), no
HIGH smells, every acceptance criterion covered, all 4 deliberate mutants
killed, and the pre-existing T009 suite passes unmodified.

## Test-first evidence

| Behavior | Class  | Evidence |
| -------- | ------ | -------- |
| A1 comparable + portable snapshots | PROVEN | cycle 1: T1/T3 red (identity `==`) → green; T2/T4 negatives |
| A2 gates | PROVEN | `dart analyze` 3 issues = master baseline; `dart test` 1080/2/0 (baseline 1073/2 + 7) |
| U1 structural equality + hash | PROVEN | cycle 1 step 2: T1 failing → green |
| U2 content differences break equality | PROVEN | T2 green (trivially red-proof under identity; guarded by M1) |
| U3 round-trip serialization | PROVEN | cycle 1 step 2: T3 failing → green; M2/M4 kills |
| U4 empty-ledger edge | PROVEN | cycle 1 step 2: T4 failing (two empties unequal) → green |
| U5 immutability | PROVEN | T5 green from the defensive copy; M3 kill proves the test bites |
| U6 sub-ledger projections | PROVEN | cycle 1 step 2: T6 failing → green; M2 kill |
| U7 chaining pin | PROVEN | pin by design; literal-arithmetic assertions (300/120/30/40) |

## Findings

No HIGH smells. Expected totals are written as literal arithmetic
(`1140`, `460`, `40`, `60`, `1600`) — not recomputed with the production
fold logic, so a wrong aggregate cannot agree with a wrong expectation.
No doubles at all (the subject is a pure value object). The `identical`
guard in T1 documents that the fixtures are instance-distinct, so the
equality assertions cannot pass by identity.

Scope note: the pin U7 chains behavior pinned by T009's value tests; the
new-members assertions (U6) are red-first. The pre-existing
`test/usage_ledger_test.dart` was NOT modified — it is the FR-005
regression guard.

## Mutation results

| Mutant | Behavior | Survived | Judgment |
| ------ | -------- | -------- | -------- |
| M1 length-only equality | U1, U2 | No | Killed: T2 — same-length different-content fixture passed as equal |
| M2 fromJson zeroes cache-read | U3, U6 | No | Killed: T3 + T6 fail (round-trip loses cache tokens) |
| M3 defensive copy removed | U5 | No | Killed: T5 — source mutation visible through the ledger |
| M4 toJson omits model | U3 | No | Killed: T3 — models lost on round-trip |

Scope: 4 of 9 behaviors sampled (the highest-risk: equality definition,
serialization fidelity, immutability). Not exhaustive; each mutant was
cp-restored and the suite re-verified green.

## Traceability

| Criterion | Tests | End to end |
| --------- | ----- | ---------- |
| FR-001 defensive copy | U5 (T5) + M3 | Yes |
| FR-002 unmodifiable entries view | U5 (T5) | Yes |
| FR-003 toJson/fromJson round-trip | U3, U4 (T3, T4) + M2, M4 | Yes |
| FR-004 equality + hashCode | U1, U2 (T1, T2) + M1 | Yes |
| FR-005 existing surface unchanged | pre-existing `test/usage_ledger_test.dart` unmodified + green; U7 | Yes |
| FR-006 sub-ledger projections | U6, U7 (T6, T7) + M2 | Yes |
| FR-007 edge cases | U4 (T4) | Yes |
| FR-008 gates | A2 | Yes |

## Gates

- `dart analyze` — 3 issues, byte-identical set to master baseline. No new
  issues introduced.
- `dart test` — **1080 passed / 2 skipped / 0 failed** (baseline 1073/2 +
  7 new; the 11-test pre-existing suite green unmodified).
