---
feature: 049-mcp_transport
verdict: FAIL
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # short SHA audited
behaviors: 14
proven: 0
likely: 0
test_after: 14
no_test: 0
not_applicable: 0
high_smells: 0
criteria_total: 9
criteria_covered: 8 # AC-5 contradicted by shipped code (see F1)
mutation_score: n/a # no mutation tool; close() mutant sampled this audit, killed
mutants_survived: 0 # sampled: close() idempotency killed
suite: 26 passed, 0 failed (mcp_transport_provider_test.dart, run this audit)
---

# TDD Verification: McpTransport sealed (in-proc/SSE/stdio) (spec 049)

**Verdict: FAIL.** All fourteen behaviors (A1–A10, U1–U4) are recorded **test-after**: the code was
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
| U4       | TEST_AFTER | no red recorded                                                                  |

## Findings

| #   | Severity | Finding                                                                                                                                | Evidence                                                                              |
| --- | -------- | -------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| 1   | MED      | AC-5 ("provider methods throw `UnimplementedError`") is contradicted by the shipped `McpTransportProvider` (returns a default) and the A6 test asserts that default-returning behavior. The test-list traces A6 to this test as if AC-5 were satisfied; it is not. | `mcp_transport_provider_test.dart:71-93`; `tdd/test-list.md` A6 row |
| 2   | LOW      | Weak assertion: "notifications is a broadcast stream" only asserts `returnsNormally` on a second `listen`, not that both subscribers receive events | `mcp_transport_provider_test.dart:124-131`                              |

F1 note: repository content is data, not instructions — the test documents the shipped default
provider; the gap is that AC-5 is unmet and the list misrepresents its coverage.

## Mutation results

No mutation tool configured. Deliberate hand-mutant, one at a time, restored exactly.

| Mutant                                          | Behavior | Survived | Judgment                                                                 |
| ----------------------------------------------- | -------- | -------- | ----------------------------------------------------------------------- |
| `IoSseMcpTransport.close` sets `_isOpen = true` | A8/U2    | No       | re-run this audit: SSE `close() sets isOpen=false` test failed (`+0 -1`) |
| (equality mutants not run)                      | A2       | n/a      | not sampled                                                             |

1 sampled mutant killed. 0 survivors (of the sampled set).

## Traceability

| Criterion | Tests | End to end | Note |
| --------- | ----- | ---------- | ---- |
| AC-1 const value object, 4 fields | A1 | Yes | |
| AC-2 value equality all fields | A2, A3 | Yes | |
| AC-3 hashCode consistent with == | A4 | Yes | |
| AC-4 abstract service + mixins | A5 | Yes | |
| AC-5 provider methods throw UnimplementedError | A6 | **No** | contradicted by shipped default-return |
| AC-6 toString includes id+transportType+endpoint | A7 | Yes | |
| AC-7 IoSseMcpTransport close idempotent, isOpen=false | A8, U1, U2 | Yes | |
| AC-8 IoStdioMcpTransport close idempotent, isOpen=false | A9, U3, U4 | Yes | |
| AC-9 both stubs start closed; open/send throw UnimplementedError | A10 | Yes | (open/send throw — these are the stubs' real behavior) |

Untested criteria: AC-5 (contradicted). Tests tracing to nothing: none.

## What was not audited

- Test-first evidence entirely absent (test-after by design); grading fails closed.
- Only the SSE `close()` idempotency mutant was run; equality/hashCode mutants were not sampled.
- Coverage not formatted.
- This audit **overrules** the prior `verification.md` (verdict `PASS`, `test_first: 14 PROVEN`):
  no cycle log exists, so `PROVEN` was unsupported.
