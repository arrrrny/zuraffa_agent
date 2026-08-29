# Tasks: Tools & MCP Client (spec 003)

> Acceptance test tasks derived from `spec.md` Acceptance Scenarios (US1–US4). The
> `[A#]` markers match the outer-loop behaviors in `tdd/test-list.md`. Each is `PENDING`
> because no acceptance/integration test drives dispatch / MCP transports yet.
> Implementation and inner-loop unit tasks are **deferred** until `plan.md` exists
> (this spec has no `plan.md`; `/speckit.tdd.plan` should be re-run then).

## Acceptance (outer loop)

- [ ] [A1] A call emitted by the loop is resolved by the single registry regardless of tool origin (DDA / generated / remote MCP).
- [ ] [A2] Arguments violating a tool's JSON Schema return a validation error as the tool result; the mission continues.
- [ ] [A3] A parallel-execution batch runs tools concurrently with results collected in call order.
- [ ] [A4] A `confirm`-risk tool awaits the approval callback; denial or timeout yields a denied tool result.
- [ ] [A5] An `admin`-risk tool on a non-internal mission is denied without invoking its implementation.
- [ ] [A6] An SSE connection dropping mid-mission reconnects (backoff) and resumes tool listing/calls.
- [ ] [A7] An expiring token rotated by the auth callback keeps calls flowing without a manager rebuild.
- [ ] [A8] In-proc tools called in a tight loop cross no serialization boundary (pass-by-reference with defensive arg copy).
- [X] [A9] An oversized tool result returned to the loop shows the model summary + artifactRef only.

## Phase 2: TDD remediation

> The feature is **not done** until the following are cleared. These cover the 4 HIGH
> findings from `tdd/verification.md` (A1, A3, A4, A5 have no test exercising the real
> entry point). Each finding's `traces` in `tdd/test-list.md` points at an entity/codegen
> test that does not exercise the acceptance behavior.

- [ ] [F1] (verification F1 — A4) Add an acceptance test that drives the real tool-dispatch
  entry point with a `confirm`-risk tool and asserts the approval callback is awaited
  and that a denial/timeout returns a denied `ToolDispatchResult` (mission continues).
  Proof: `dart test <new test>` fails red, then passes green after the gating is wired.
  - file:line: `test/data/providers/agent_tool/agent_tool_provider_test.dart:27-177`
    (enum/entity/registry only; no `checkRiskTier`-deny test exists in `test/**`)

- [ ] [F2] (verification F2 — A5) Add an acceptance test that drives a real `ToolDispatcher`
  with an `admin`-risk tool on a non-internal mission and asserts the call is denied
  without the implementation being invoked (`checkRiskTier` returns deny).
  Proof: `dart test <new test>` fails red, then passes green.
  - file:line: `test/data/providers/agent_tool/agent_tool_provider_test.dart:27-177`

- [ ] [F3] (verification F3 — A1) Add an acceptance test that registers tools from DDA,
  generated, and remote-MCP origins and asserts a single `ToolRegistry` resolves each by
  name regardless of origin (deterministic prefixing on collision).
  Proof: `dart test <new test>` fails red, then passes green.
  - file:line: `test/data/providers/tool_registry/tool_registry_provider_test.dart:13-106`
    (entity equality only; no resolve-across-origins test)

- [ ] [F4] (verification F4 — A3) Add an acceptance test that dispatches a parallel-mode
  batch and asserts the tools run concurrently (wall-clock < sequential sum) and results
  are collected in call order.
  Proof: `dart test <new test>` fails red, then passes green.
  - file:line: `test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart:15-172`
    (entity/codegen only; no behavioral parallel-batch test)
