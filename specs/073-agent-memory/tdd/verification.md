---
feature: 073-agent-memory
verdict: PASS_WITH_GAPS
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # short SHA audited (working tree HEAD)
behaviors: 11
proven: 0
likely: 11
test_after: 0
no_test: 0
high_smells: 0
criteria_total: 10
criteria_covered: 10
mutation_score: 100 # deliberate sample only (no mutation tool): 5/5 highest-risk behaviors killed
mutants_survived: 0
suite: 11 passed, 0 failed # test/engine/agent_memory_test.dart at 01618f3
---

# TDD Verification: Agent memory — three layers (spec 073)

**Verdict: PASS_WITH_GAPS.** No `cycle-log.md` exists and the branch history is
squashed/stacked, so test-first order cannot be corroborated; every behavior is
graded `LIKELY`. No HIGH smells, no untested criteria, and all 5 sampled
deliberate mutants (highest-risk: cross-layer recall ranking) were killed.

## Test-first evidence

`specs/073-agent-memory/tdd/cycle-log.md` does not exist; commits squashed on
the stacked branch. Every behavior graded `LIKELY`.

| Behavior | Class  | Evidence |
| -------- | ------ | -------- |
| A1 three-layer story (remember/link/recall/promote) | LIKELY | no cycle-log.md; squashed history; passes at HEAD |
| A2 recall ranking salience then recency | LIKELY | same |
| A3 recall limit + empty-query guard | LIKELY | same |
| A4 graph integrity (link validation, idempotence) | LIKELY | same |
| A5 promote semantics | LIKELY | same |
| A6 session evaporate + honest dangling links | LIKELY | same |
| A7 gates | LIKELY | same |
| U1–U4 value objects, long-term/session stores, graph traversal | LIKELY | same |

## Findings

No HIGH smells. Gap is the missing cycle log (drives `LIKELY`). Repo-wide
analyze gate red at HEAD (3 issues) but all in out-of-scope files.

## Mutation results

Deliberate mutants on the highest-risk behaviors (cross-layer recall, promote,
graph direction). One change each, observed fail, restored, green. All 5 killed:

| Mutant | Behavior | Survived | Judgment |
| ------ | -------- | -------- | -------- |
| M1 recall sorted by insertion order (salience dropped) | A2 | No | Killed: ranking assert |
| M2 recall searches long-term store only | A1, A2 | No | Killed: session hit vanishes |
| M3 promote copies but does not remove from session store | A5 | No | Killed: forSession must be empty |
| M4 neighborsOf returns outgoing only | U4 | No | Killed: incoming link invisible |
| M5 duplicate (from,to,type) link throws | A4 | No | Killed: re-link must not throw |

Scope: 5 of 11 behaviors sampled (recall + graph). Not exhaustive.

## Traceability

| Criterion | Tests | End to end |
| --------- | ----- | ---------- |
| FR-001 record/source/link/hit value semantics | U1 | Yes |
| FR-002 long-term store | U2 | Yes |
| FR-003 session store (scoping, evaporate) | U3, A6 | Yes |
| FR-004 link types + direction | U1, U4 | Yes |
| FR-005 graph traversal/filters/idempotence | U4, A4 | Yes |
| FR-006 facade routing | A1 | Yes |
| FR-007 recall across layers, ranking, limit, empty guard | A1, A2, A3 | Yes |
| FR-008 link integrity + honest dangling resolution | A4, A6 | Yes |
| FR-009 promote move semantics | A5 | Yes |
| FR-010 gates | A7 | Yes |

Untested criteria: none. Tests tracing to nothing: none.

## What was not audited

- `cycle-log.md` absent → ordering unverified (`LIKELY`).
- Mutation scoped to a 5-behavior sample; not exhaustive (no mutation tool).
- Coverage not measured (`package:coverage` not installed).
- Repo-wide analyze gate red (3 issues) in files outside this spec.
