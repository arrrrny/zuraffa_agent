---
feature: 078-request-response
verdict: PASS_WITH_GAPS
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # short SHA audited (working tree HEAD)
behaviors: 9
proven: 0
likely: 9
test_after: 0
no_test: 0
high_smells: 0
criteria_total: 9
criteria_covered: 9
mutation_score: 100 # deliberate sample only (no mutation tool): 6/6 highest-risk behaviors killed
mutants_survived: 0
suite: 8 passed, 0 failed # test/events/request_response_test.dart at 01618f3
---

# TDD Verification: Request/response pattern (spec 078)

**Verdict: PASS_WITH_GAPS.** No `cycle-log.md` exists and the branch history is
squashed/stacked; every behavior graded `LIKELY`. No HIGH smells, no untested
criteria, and all 6 sampled deliberate mutants (highest-risk: handler override /
last-registered-wins) were killed.

## Test-first evidence

`specs/078-request-response/tdd/cycle-log.md` does not exist; commits squashed on
the branch. Every behavior graded `LIKELY`.

| Behavior | Class  | Evidence |
| -------- | ------ | -------- |
| A1 controller.request round-trip | LIKELY | no cycle-log.md; squashed history; passes at HEAD |
| A2 controller/bus parity | LIKELY | same |
| A3 gates | LIKELY | same |
| U1 controller.on alias | LIKELY | same |
| U2 last-registered handler responds | LIKELY | same |
| U3 handler exceptions propagate | LIKELY | same |
| U4 no-handler StateError | LIKELY | same |
| U5 response type honesty | LIKELY | same |
| U6 live registration + type independence | LIKELY | same |

## Findings

No HIGH smells. Gap is the missing cycle log (drives `LIKELY`). Repo-wide analyze
gate red at HEAD (3 issues) but all in out-of-scope files. (Note: U2–U6 pin
behavior that landed on master unguarded; they pass by design and are justified by
the killer mutants below.)

## Mutation results

Deliberate mutants on the highest-risk behaviors (delegation, override semantics,
error propagation, type honesty). One change each, observed fail, restored,
green. All 6 killed:

| Mutant | Behavior | Survived | Judgment |
| ------ | -------- | -------- | -------- |
| M1 `controller.request` throws UnimplementedError | A1, A2 | No | Killed: both controller.request tests |
| M2 `controller.on` is a no-op | U1 | No | Killed: alias test |
| M3 bus dispatches to first-registered handler | U2 | No | Killed: `Expected: 'second'` |
| M4 bus swallows handler exceptions | U3 | No | Killed: propagation pin |
| M5 no-handler StateError removed | U4 | No | Killed: wrong error type |
| M6 `as R` response cast erased | U5 | No | Killed at compile time (`return_of_invalid_type`) |

Scope: 6 of 9 behaviors sampled (the unguarded master behavior). Not exhaustive;
M6's kill is at compile time (documented).

## Traceability

| Criterion | Tests | End to end |
| --------- | ----- | ---------- |
| FR-001 controller.request parity | A1, A2 | Yes |
| FR-002 controller.on alias | U1 | Yes |
| FR-003 bus getter (transparent wrap) | A1, A2, U6 | Yes |
| FR-004 last-registered responds | U2 | Yes |
| FR-005 exception propagation | U3 | Yes |
| FR-006 no-handler StateError | U4 | Yes |
| FR-007 type honesty | U5 | Yes |
| FR-008 live registration + type independence | U6 | Yes |
| FR-009 gates | A3 | Yes |

Untested criteria: none. Tests tracing to nothing: none.

## What was not audited

- `cycle-log.md` absent → ordering unverified (`LIKELY`).
- Mutation scoped to a 6-behavior sample; not exhaustive (no mutation tool).
- Coverage not measured (`package:coverage` not installed).
- Repo-wide analyze gate red (3 issues) in files outside this spec.
