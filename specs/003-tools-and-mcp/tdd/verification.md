---
feature: 003-tools-and-mcp
verdict: FAIL
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # short SHA audited
behaviors: 9
proven: 0
likely: 0
test_after: 9
no_test: 0
high_smells: 4
criteria_total: 9
criteria_covered: 5 # A2,A6,A7,A8,A9 have a real passing test somewhere; A1,A3,A4,A5 do not
mutation_score: 100 # scope: 1 of 9 behaviors sampled (A6), 0 survived
mutants_survived: 0 # A6 mutant killed
suite: 946 passed, 2 skipped (baseline from cycle log; A6 mutant re-run green)
---

# TDD Verification: Tools & MCP Client (spec 003)

**Verdict: FAIL.** All nine acceptance behaviors are `TEST_AFTER` — no red cycle was
driven in this feature's loop (A6's only red was a *broken-test* compile error, which
the playbook does not count; its first real run passed). Worse, the `test-list.md`
`DONE` claims rest on sibling tests that verify only the **entity / codegen /
clean-arch layer** of each component, not the acceptance behavior. Four criteria
(A1, A3, A4, A5) are exercised by **no test at all** at their real entry point; A4
and A5 (security risk-gating) are not exercised anywhere in the repository. The
remaining four (A2, A7, A8, A9) are genuinely covered, but by *other* sibling unit
tests, so their `traces` are mis-cited. This is a traceability failure, not merely a
discipline gap.

## Test-first evidence

| Behavior | Class      | Evidence                                                                                              |
| -------- | ---------- | ----------------------------------------------------------------------------------------------------- |
| A1       | TEST_AFTER | Credited to `tool_registry_provider_test.dart`; that file tests entity equality only (no resolve test) |
| A2       | TEST_AFTER | Credited to `tool_dispatch_mode_provider_test.dart`; entity/codegen only; validation covered elsewhere |
| A3       | TEST_AFTER | Credited to `tool_dispatch_mode_provider_test.dart`; entity/codegen only; no parallel-batch test       |
| A4       | TEST_AFTER | Credited to `agent_tool_provider_test.dart`; enum/entity/registry only; gating tested nowhere          |
| A5       | TEST_AFTER | Credited to `agent_tool_provider_test.dart`; enum/entity/registry only; gating tested nowhere         |
| A6       | TEST_AFTER | cycle A6 "broken-test red" (compile error, not counted); first real run passed; deliberate mutant killed |
| A7       | TEST_AFTER | Credited to `mcp_transport_provider_test.dart`; entity/stub only; token rotation covered elsewhere    |
| A8       | TEST_AFTER | Credited to `tool_dispatch_mode_provider_test.dart`; entity only; in-proc path covered elsewhere       |
| A9       | TEST_AFTER | Credited to `oversized_result_policy_provider_test.dart`; entity only; behavior covered elsewhere      |

## Findings

| #   | Severity | Finding                                                                                                                                                    | Evidence                                                                                       |
| --- | -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| 1   | HIGH     | A4 (confirm-risk awaits approval callback; denial/timeout → denied result) is marked DONE but the cited test never exercises the dispatch-time approval decision. No test in the repo asserts the approval callback is awaited or that denial/timeout yields a denied `ToolDispatchResult` — the only `checkRiskTier` usages in tests are fakes that always return `true`. | `test/data/providers/agent_tool/agent_tool_provider_test.dart:27-177` (enum/entity/registry only); `grep checkRiskTier` in `test/**` shows only fakes returning `true` |
| 2   | HIGH     | A5 (admin-risk tool on a non-internal mission denied without invoking its implementation) is marked DONE but untested anywhere. The cited entity test does not assert the admin/non-internal deny decision at the dispatch entry point. | `agent_tool_provider_test.dart:27-177`; no `checkRiskTier`-returns-deny test exists in `test/**` |
| 3   | HIGH     | A1 (single registry resolves a call regardless of tool origin DDA/generated/remote MCP) is marked DONE but the cited test verifies only `ToolRegistry` value equality/toString. No behavioral resolve-across-origins test exists. | `test/data/providers/tool_registry/tool_registry_provider_test.dart:13-106` |
| 4   | HIGH     | A3 (parallel batch runs concurrently, results collected in call order) is marked DONE but the cited test verifies only the `ToolDispatchMode` entity/codegen. No behavioral parallel-batch test exists (only the `parallel` enum string). | `test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart:15-172` |
| 5   | MED      | A2 (schema validation error → tool result, mission continues) is mis-cited: the credited entity test does not cover it, but `validateSchema` error handling IS exercised by `test/engine/memory_tools_test.dart` and the engine suite. Re-point the trace. | `tool_dispatch_mode_provider_test.dart:103-172` (codegen only); behavior in `test/engine/memory_tools_test.dart` |
| 6   | MED      | A7 (expiring token rotated by auth callback keeps calls flowing) is mis-cited: the credited entity test does not cover it, but token rotation IS exercised by `test/mcp/sse_mcp_client_test.dart`. Re-point the trace. | `mcp_transport_provider_test.dart:16-172` (entity/stub); behavior in `test/mcp/sse_mcp_client_test.dart` |
| 7   | MED      | A8 (in-proc tools cross no serialization boundary) is mis-cited: the credited entity test does not cover it, but the in-proc path IS exercised by `test/mcp/in_proc_mcp_client_test.dart`. Re-point the trace. | `tool_dispatch_mode_provider_test.dart:15-172`; behavior in `test/mcp/in_proc_mcp_client_test.dart` |
| 8   | MED      | A9 (oversized result → model summary + artifactRef only) is mis-cited: the credited entity test does not cover it, but oversized/artifactRef behavior IS exercised by `test/domain/entities/tool_result/tool_result_test.dart` and the engine suite. Re-point the trace. | `oversized_result_policy_provider_test.dart:11-52` (entity); behavior in `tool_result_test.dart` |

No HIGH *test smell* (tautology / doubled subject / assertion-free) was found in the
tests that exist; the failures here are **missing or mis-cited tests**, not weak
assertions. The one genuine cycle (A6) is a real acceptance test whose assertions are
value-bearing (wire reopen count, backoff reset), and its deliberate mutant was killed.

## Mutation results

| Mutant                                                     | Behavior | Survived | Judgment                                                                                       |
| ---------------------------------------------------------- | -------- | -------- | ---------------------------------------------------------------------------------------------- |
| removed `_reconnect.reset()` from the successful-send path | A6       | No       | A6 failed (`Actual: [0:00:00.100000, 0:00:00.200000]` — backoff escalated instead of restarting); restored |

Scope: 1 of 9 behaviors sampled (the only one with a cycle). Mutants survived: 0.

## Traceability

| Criterion | Tests (cited → real)                                                        | End to end |
| --------- | --------------------------------------------------------------------------- | ---------- |
| A1        | cited `tool_registry_provider_test.dart` → entity only; **no behavioral test** | **No** (F3) |
| A2        | cited entity test → real coverage in `memory_tools_test.dart`                | Yes (elsewhere) |
| A3        | cited entity test → **no behavioral test**                                   | **No** (F4) |
| A4        | cited entity test → **no test anywhere**                                     | **No** (F1) |
| A5        | cited entity test → **no test anywhere**                                     | **No** (F2) |
| A6        | `mcp_003_a6_reconnect_test.dart` (real, mutant-killed)                       | Yes        |
| A7        | cited entity test → real coverage in `sse_mcp_client_test.dart`              | Yes (elsewhere) |
| A8        | cited entity test → real coverage in `in_proc_mcp_client_test.dart`          | Yes (elsewhere) |
| A9        | cited entity test → real coverage in `tool_result_test.dart`                 | Yes (elsewhere) |

Untested criteria: A1, A3, A4, A5 (no test exercises the real entry point). Tests
tracing to nothing: none — but four `traces` values point at tests that do not test
the behavior they claim (F1–F4), which is the rubric's "list is lying about coverage"
condition.

## Post-audit correction (2026-08-29)

Finding #8 (A9 mis-cited) is now resolved. The oversized-result discipline is no
longer only an entity/value-object assertion — it is exercised end-to-end through
the real mission loop:

- New `OversizedResultPolicyDispatcher` (a `ToolDispatcher` decorator, `lib/src/engine/oversized_result_policy_dispatcher.dart`) enforces the active `OversizedResultPolicy` on every dispatched result; `SubAgentDispatchService` now wraps its child-mission dispatcher with it (`lib/src/engine/sub_agent_dispatch.dart`), so large tool bodies are summarized + artifactRef'd before reaching model context (spec-003 §4.3, FR-005 / SC-003 / R3#3).
- `test/engine/oversized_result_policy_dispatcher_test.dart` covers both the per-result converter (`enforceOversizedResultPolicyOnDispatch`) and an integration case that runs a 2 MB tool result through `MissionRunner` and asserts the model-facing transcript carries the summary only (never the full 2 MB body) with the artifactRef recorded, and the full body is retrievable from the store.
- `tdd/test-list.md` A9 trace and `tasks.md` A9 are updated accordingly; A9 remains DONE with real end-to-end coverage.

## What was not audited

- The full suite was not re-run end to end; only A6's mutant test was executed (re-run
  green after restore). Baseline green is taken from the cycle log (946 passed, 2 skipped).
- Inner-loop unit behaviors are deferred (`plan.md` absent for this feature).
- The sibling unit tests that *do* cover A2/A7/A8/A9 were spot-read for the behavioral
  assertion via grep, not fully re-read; the claim is that the cited `traces` are wrong,
  which holds regardless of where the real tests live.
- `dart analyze` was not re-run; the merged `master` baseline is assumed clean.
