---
feature: 074-memory-tools
verdict: PASS_WITH_GAPS
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # short SHA audited (working tree HEAD)
behaviors: 15
proven: 0
likely: 15
test_after: 0
no_test: 0
high_smells: 0
criteria_total: 9
criteria_covered: 9
mutation_score: 100 # deliberate sample only (no mutation tool): 5/5 highest-risk behaviors killed
mutants_survived: 0
suite: 14 passed, 0 failed # test/engine/memory_tools_test.dart at 01618f3
---

# TDD Verification: Memory tools — agent-facing surface (spec 074)

**Verdict: PASS_WITH_GAPS.** No `cycle-log.md` exists and the branch history is
squashed/stacked; every behavior graded `LIKELY`. No HIGH smells, no untested
criteria, and all 5 sampled deliberate mutants (highest-risk: `session_id`
routing + write-through) were killed.

## Test-first evidence

`specs/074-memory-tools/tdd/cycle-log.md` does not exist; commits squashed on the
stacked branch `feat/spec-074-memory-tools`. Every behavior graded `LIKELY`.

| Behavior | Class  | Evidence |
| -------- | ------ | -------- |
| A1–A6 acceptance (agent story, session routing, failure results, dispatchBatch, projection, gates) | LIKELY | no cycle-log.md; squashed history; passes at HEAD |
| U1–U9 unit (declarations, remember, recall, link, schema, auto-id, NaN salience, null arg, per-layer limit) | LIKELY | same |

## Findings

No HIGH smells. Gap is the missing cycle log (drives `LIKELY`). Repo-wide
analyze gate red at HEAD (3 issues) but all in out-of-scope files.

## Mutation results

Deliberate mutants on the highest-risk behaviors (write path + `session_id`
routing). One change each, observed fail, restored, green. All 5 killed:

| Mutant | Behavior | Survived | Judgment |
| ------ | -------- | -------- | -------- |
| M1 remember returns success but never writes | A1, A2 | No | Killed: store-empty / recall assertions |
| M2 recall limit ignored | U3 | No | Killed: `Expected: length 1` |
| M3 link type hardcoded `relatesTo` | U4 | No | Killed: typed assertion via `linksOf` |
| M4 projection renders insertion order, not salience desc | A5 | No | Killed: top-2 wrong order |
| M5 `session_id` argument ignored (everything long-term) | A2 | No | Killed: session store empty after scoped write |

Scope: 5 of 15 behaviors sampled (routing + persistence boundary). Not exhaustive.

## Traceability

| Criterion | Tests | End to end |
| --------- | ----- | ---------- |
| FR-001 declarations (safe-tier typed tools) | U1 | Yes |
| FR-002 remember dispatch + routing | U2, A2 | Yes |
| FR-003 failure results, not exceptions | A3 | Yes |
| FR-004 recall lines + limit | U3 | Yes |
| FR-005 link dispatch | U4 | Yes |
| FR-006 dispatchBatch | A4 | Yes |
| FR-007 validateSchema + checkRiskTier | U5, U8 | Yes |
| FR-008 prompt projection | A5, U9 | Yes |
| FR-009 gates | A6 | Yes |

Untested criteria: none. Tests tracing to nothing: none.

## What was not audited

- `cycle-log.md` absent → ordering unverified (`LIKELY`).
- Mutation scoped to a 5-behavior sample; not exhaustive (no mutation tool).
- Coverage not measured (`package:coverage` not installed).
- Repo-wide analyze gate red (3 issues) in files outside this spec.
