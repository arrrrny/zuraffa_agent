---
feature: 077-memory-distiller
verdict: PASS_WITH_GAPS
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # short SHA audited (working tree HEAD)
behaviors: 10
proven: 0
likely: 10
test_after: 0
no_test: 0
high_smells: 0
criteria_total: 11
criteria_covered: 11
mutation_score: 100 # deliberate sample only (no mutation tool): 5/5 highest-risk behaviors killed
mutants_survived: 0
suite: 10 passed, 0 failed # test/engine/memory_distiller_test.dart at 01618f3
---

# TDD Verification: Memory distiller (spec 077)

**Verdict: PASS_WITH_GAPS.** No `cycle-log.md` exists and the branch history is
squashed/stacked; every behavior graded `LIKELY`. No HIGH smells, no untested
criteria, and all 5 sampled deliberate mutants (highest-risk: duplicate guard)
were killed.

## Test-first evidence

`specs/077-memory-distiller/tdd/cycle-log.md` does not exist; commits squashed on
the stacked branch. Every behavior graded `LIKELY`.

| Behavior | Class  | Evidence |
| -------- | ------ | -------- |
| A1 mixed-salience distill (gate, identity, residue) | LIKELY | no cycle-log.md; squashed history; passes at HEAD |
| A2 duplicate guard | LIKELY | same |
| A3 cap (best N, older-first tie-break) | LIKELY | same |
| A4 idempotency | LIKELY | same |
| A5 durability over 076 stores | LIKELY | same |
| A6 gates | LIKELY | same |
| U1 policy value semantics | LIKELY | same |
| U2 boundary == threshold (default 0.7) | LIKELY | same |
| U3 report accounting | LIKELY | same |
| U4 unknown/empty session → empty report | LIKELY | same |

## Findings

No HIGH smells. Gap is the missing cycle log (drives `LIKELY`). Repo-wide analyze
gate red at HEAD (3 issues) but all in out-of-scope files.

## Mutation results

Deliberate mutants on the highest-risk behaviors (gate, duplicate guard, cap,
ranking). One change each, observed fail, restored, green. All 5 killed:

| Mutant | Behavior | Survived | Judgment |
| ------ | -------- | -------- | -------- |
| M1 salience gate inverted (`<` vs `>=`) | A1 | No | Killed: weak records promoted |
| M2 duplicate guard dropped | A2 | No | Killed: known content re-promoted |
| M3 cap not enforced | A3 | No | Killed: all five promoted |
| M4 ranking inverted (salience asc, newer first) | A1 | No | Killed: promotion-order assert |
| M5 promote never called (report fabricated) | A1, A2, A5 | No | Killed: long-term never grows |

Scope: 5 of 10 behaviors sampled (gate + dedup + cap + ranking). Not exhaustive.

## Traceability

| Criterion | Tests | End to end |
| --------- | ----- | ---------- |
| FR-001 policy value semantics + validation | U1 | Yes |
| FR-002 gate + identity-preserving promotion | A1 | Yes |
| FR-003 boundary == threshold (default 0.7) | U2 | Yes |
| FR-004 duplicate guard | A2 | Yes |
| FR-005 cap + ranking | A3 | Yes |
| FR-006 below-threshold skipped + stays | A1 | Yes |
| FR-007 idempotency | A4 | Yes |
| FR-008 unknown session → empty report | U4 | Yes |
| FR-009 report full accounting | U3 | Yes |
| FR-010 durability over 076 stores | A5 | Yes |
| FR-011 gates | A6 | Yes |

Untested criteria: none. Tests tracing to nothing: none.

## What was not audited

- `cycle-log.md` absent → ordering unverified (`LIKELY`).
- Mutation scoped to a 5-behavior sample; not exhaustive (no mutation tool).
- Coverage not measured (`package:coverage` not installed).
- Repo-wide analyze gate red (3 issues) in files outside this spec.
