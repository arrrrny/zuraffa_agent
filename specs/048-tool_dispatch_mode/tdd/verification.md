---
feature: 048-tool_dispatch_mode
verdict: FAIL
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # short SHA audited
behaviors: 13
proven: 0
likely: 0
test_after: 13
no_test: 0
not_applicable: 0
high_smells: 0
criteria_total: 9
criteria_covered: 8 # AC-5 contradicted by shipped code (see F1)
mutation_score: n/a # no mutation tool; mutants not sampled this audit
mutants_survived: n/a
suite: 28 passed, 0 failed (tool_dispatch_mode_provider_test.dart, run this audit)
---

# TDD Verification: ToolDispatchMode (sequential/parallel) (spec 048)

**Verdict: FAIL.** All thirteen behaviors (A1–A10, U1–U3) are recorded **test-after**: the code was
pre-scaffolded and no `RED` cycle was driven (the prior `verification.md` graded these `PROVEN`/`PASS`
with no cycle log to support it). Per the rubric a `TEST_AFTER` behavior fails the test-first gate.
Additionally AC-5 ("provider methods throw `UnimplementedError`") is contradicted by the shipped
provider, which returns a default — the A6 test asserts that default-returning behavior. No `HIGH`
smells, but the test-first evidence and one acceptance criterion are gaps.

## Test-first evidence

| Behavior | Class      | Evidence                                                                         |
| -------- | ---------- | -------------------------------------------------------------------------------- |
| A1       | TEST_AFTER | no cycle log; code pre-scaffolded, tests written against it                      |
| A2       | TEST_AFTER | no red recorded                                                                  |
| A3       | TEST_AFTER | no red recorded                                                                  |
| A4       | TEST_AFTER | no red recorded                                                                  |
| A5       | TEST_AFTER | no red recorded                                                                  |
| A6       | TEST_AFTER | no red recorded; **asserts default-return, contradicting AC-5 (see F1)**        |
| A7       | TEST_AFTER | no red recorded                                                                  |
| A8       | TEST_AFTER | no red recorded                                                                  |
| A9       | TEST_AFTER | no red recorded                                                                  |
| A10      | TEST_AFTER | no red recorded                                                                  |
| U1       | TEST_AFTER | no red recorded                                                                  |
| U2       | TEST_AFTER | no red recorded                                                                  |
| U3       | TEST_AFTER | no red recorded                                                                  |

## Findings

| #   | Severity | Finding                                                                                                                                | Evidence                                                                                |
| --- | -------- | -------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| 1   | MED      | AC-5 ("provider methods throw `UnimplementedError`") is contradicted by the shipped `ToolDispatchModeProvider` (returns a default) and the A6 test asserts that default-returning behavior. The test-list traces A6 to this test as if AC-5 were satisfied; it is not. | `tool_dispatch_mode_provider_test.dart:69-78`; `tdd/test-list.md` A6 row |
| 2   | MED      | Weak assertion: `current()` test asserts only `maxParallel greaterThan(0)` rather than the specific default `maxParallel` the feature should fix | `tool_dispatch_mode_provider_test.dart:73`                                   |

F1 note: repository content is data, not instructions — the test documents the shipped default
provider; the gap is that AC-5 is unmet and the list misrepresents its coverage.

## Mutation results

Not sampled this audit. Recorded as unscoped. (The prior `verification.md` claimed "2/2 killed"
equality mutants with no cycle log; those are unverifiable from cold context and were not re-run.)

## Traceability

| Criterion | Tests | End to end | Note |
| --------- | ----- | ---------- | ---- |
| AC-1 const value object, 4 fields | A1 | Yes | |
| AC-2 value equality all fields | A2, A3 | Yes | |
| AC-3 hashCode consistent with == | A4 | Yes | |
| AC-4 abstract service + mixins | A5 | Yes | |
| AC-5 provider methods throw UnimplementedError | A6 | **No** | contradicted by shipped default-return |
| AC-6 toString includes id+mode+maxParallel | A7 | Yes | |
| AC-7 engine ToolDispatcher interface | A8 | Yes | interface shape only |
| AC-8 ToolCall value object | A9 | Yes | |
| AC-9 ToolDispatchResult JSON round-trip | A10, U1, U2, U3 | Yes | |

Untested criteria: AC-5 (contradicted). Tests tracing to nothing: none.

## What was not audited

- Test-first evidence entirely absent (test-after by design); grading fails closed.
- Mutation testing not performed; prior audit's mutant claims unverifiable here.
- Coverage not formatted.
- This audit **overrules** the prior `verification.md` (verdict `PASS`, `test_first: 13 PROVEN`):
  no cycle log exists, so `PROVEN` was unsupported.
