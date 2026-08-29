---
feature: 076-memory-persistence
verdict: PASS_WITH_GAPS
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # short SHA audited (working tree HEAD)
behaviors: 14
proven: 0
likely: 14
test_after: 0
no_test: 0
high_smells: 0
criteria_total: 10
criteria_covered: 10
mutation_score: 100 # deliberate sample only (no mutation tool): 5/5 highest-risk behaviors killed
mutants_survived: 0
suite: 15 passed, 0 failed # test/engine/persistent_agent_memory_test.dart at 01618f3
---

# TDD Verification: Agent memory persistence (spec 076)

**Verdict: PASS_WITH_GAPS.** No `cycle-log.md` exists and the branch history is
squashed/stacked; every behavior graded `LIKELY`. No HIGH smells, no untested
criteria, and all 5 sampled deliberate mutants (highest-risk: write-through /
atomicity, the behaviors the mutant plan skipped but which the suite pins
directly) were killed.

## Test-first evidence

`specs/076-memory-persistence/tdd/cycle-log.md` does not exist; commits squashed
on the stacked branch. Every behavior graded `LIKELY`.

| Behavior | Class  | Evidence |
| -------- | ------ | -------- |
| A1 restart round-trip | LIKELY | no cycle-log.md; squashed history; passes at HEAD |
| A2 crash-safety (no `.tmp`, valid JSON) | LIKELY | same |
| A3 corrupt-entry skip / corrupt-file loud | LIKELY | same |
| A4 full-system promote survives restart | LIKELY | same |
| A5 gates | LIKELY | same |
| U1–U9 codec, write-through, same-id replace, restore, graph, dir creation, shape/version/tags guards | LIKELY | same |

## Findings

No HIGH smells. Gap is the missing cycle log (drives `LIKELY`). Repo-wide analyze
gate red at HEAD (3 issues) but all in out-of-scope files.

## Mutation results

Deliberate mutants on the highest-risk behaviors (write-through + atomicity — the
persistence correctness surface). One change each, observed fail, restored,
green. All 5 killed:

| Mutant | Behavior | Survived | Judgment |
| ------ | -------- | -------- | -------- |
| M1 `remember` drops the write-through call | U2, A1 | No | Killed: file must exist / round-trip stale |
| M2 `restore` returns before loading (no-op) | A1, A4 | No | Killed: `Expected: length <1>` |
| M3 per-entry malformed-skip removed | A3 | No | Killed: skip test fails |
| M4 atomic write stops at `*.tmp` (rename skipped) | A2 | No | Killed: file never lands |
| M5 codec drops `tags` on decode | U1, A1 | No | Killed: value-equality diff |

Scope: 5 of 14 behaviors sampled (persistence + atomicity). Not exhaustive.

## Traceability

| Criterion | Tests | End to end |
| --------- | ----- | ---------- |
| FR-001 codec lossless round-trip | U1 | Yes |
| FR-002 long-term write-through | U2, A1 | Yes |
| FR-003 restore + missing file | A1, U4 | Yes |
| FR-004 malformed skip / corrupt loud | A3, U7, U8, U9 | Yes |
| FR-005 same-id replace no duplication | U3 | Yes |
| FR-006 graph write-through + restore | U5 | Yes |
| FR-007 atomic writes | A2, U6 | Yes |
| FR-008 facade composition incl. promote | A4 | Yes |
| FR-009 session store not persisted | A4 (session note survives via promotion) | Yes |
| FR-010 gates | A5 | Yes |

Untested criteria: none. Tests tracing to nothing: none.

## What was not audited

- `cycle-log.md` absent → ordering unverified (`LIKELY`).
- Mutation scoped to a 5-behavior sample; not exhaustive (no mutation tool).
- Coverage not measured (`package:coverage` not installed).
- Repo-wide analyze gate red (3 issues) in files outside this spec.
