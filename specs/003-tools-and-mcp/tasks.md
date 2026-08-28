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
- [ ] [A9] An oversized tool result returned to the loop shows the model summary + artifactRef only.
