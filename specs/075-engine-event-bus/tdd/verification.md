---
feature: 075-engine-event-bus
verdict: PASS_WITH_GAPS
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # short SHA audited (working tree HEAD)
behaviors: 9
proven: 0
likely: 9
test_after: 0
no_test: 0
high_smells: 0
criteria_total: 7
criteria_covered: 7
mutation_score: 100 # deliberate sample only (no mutation tool): 5/5 highest-risk behaviors killed
mutants_survived: 0
suite: 8 passed, 0 failed # test/engine/engine_event_bus_test.dart at 01618f3
---

# TDD Verification: Engine event bus (spec 075)

**Verdict: PASS_WITH_GAPS.** No `cycle-log.md` exists and the branch history is
squashed/stacked; every behavior graded `LIKELY`. No HIGH smells, no untested
criteria, and all 5 sampled deliberate mutants (highest-risk: error isolation)
were killed.

## Test-first evidence

`specs/075-engine-event-bus/tdd/cycle-log.md` does not exist; commits squashed on
the branch. Every behavior graded `LIKELY`.

| Behavior | Class  | Evidence |
| -------- | ------ | -------- |
| A1 fan-out to many subscribers | LIKELY | no cycle-log.md; squashed history; passes at HEAD |
| A2 error isolation (throwing subscriber never breaks delivery) | LIKELY | same |
| A3 replay broadcasts history | LIKELY | same |
| A4 onEvent bridge | LIKELY | same |
| A5 gates | LIKELY | same |
| U1–U4 typed delivery, registration order, cancel, subscriberCount | LIKELY | same |

## Findings

No HIGH smells. Gap is the missing cycle log (drives `LIKELY`). Repo-wide analyze
gate red at HEAD (3 issues) but all in out-of-scope files.

## Mutation results

Deliberate mutants on the highest-risk behaviors (fan-out, type filter, isolation,
cancel). One change each, observed fail, restored, green. All 5 killed:

| Mutant | Behavior | Survived | Judgment |
| ------ | -------- | -------- | -------- |
| M1 publish delivers to first matching subscriber only | A1 | No | Killed: second same-type subscriber starves |
| M2 type filter dropped (every subscriber invoked) | U1 | No | Killed: TurnStarted subscriber receives TurnCompleted |
| M3 replay iterates history reversed | A3 | No | Killed: `Expected: ['t1','t2','t3']` |
| M4 isolation removed (exceptions propagate) | A2 | No | Killed: publish throws / second subscriber starves |
| M5 cancel is a no-op | U3 | No | Killed: delivery continues after cancel |

Scope: 5 of 9 behaviors sampled (delivery + isolation). Not exhaustive.

## Traceability

| Criterion | Tests | End to end |
| --------- | ----- | ---------- |
| FR-001 typed subscription + wildcard | U1 | Yes |
| FR-002 sync publish, registration order, fan-out | U2, A1, A4 | Yes |
| FR-003 error isolation + hook | A2 | Yes |
| FR-004 cancel semantics | U3 | Yes |
| FR-005 replay broadcast | A3 | Yes |
| FR-006 subscriberCount | U4 | Yes |
| FR-007 gates | A5 | Yes |

Untested criteria: none. Tests tracing to nothing: none.

## What was not audited

- `cycle-log.md` absent → ordering unverified (`LIKELY`).
- Mutation scoped to a 5-behavior sample; not exhaustive (no mutation tool).
- Coverage not measured (`package:coverage` not installed).
- Repo-wide analyze gate red (3 issues) in files outside this spec.
