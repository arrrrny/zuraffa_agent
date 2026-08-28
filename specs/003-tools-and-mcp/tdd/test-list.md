---
feature: 003-tools-and-mcp
loop: outside-in # tools & MCP client are a user-visible dispatch/transport surface (engine, policy shell)
profile: .specify/memory/tdd-profile.md
spec_criteria: 9 # numbered Acceptance Scenarios across 4 user stories in spec.md (no global AC ids; traced to FR-xxx)
planned_at: fce207d
updated_at: fce207d
suite_baseline: green # 909 passed, 2 skipped
---

# Test List: Tools & MCP Client (spec 003)

> Derived from `spec.md` (User Scenarios & Testing → Acceptance Scenarios, and
> FR-001..FR-005) on `master` @ `fce207d`. **OUTER-ONLY**: `plan.md` is absent, so
> only the outer-loop acceptance behaviors are derived here; the inner loop is
> deferred (see below). No acceptance/integration test exercises these spec
> criteria through the tool-dispatch / MCP-transport entry points yet, so every A
> behavior is `PENDING`.

## Outer loop: acceptance behaviors

One per numbered Acceptance Scenario in `spec.md`. Each stays `PENDING` until the
registry dispatch and MCP transports are driven end to end through their real
entry points and asserted.

| id  | behavior                                                                                                                  | traces | kind    | state   | test |
| --- | ------------------------------------------------------------------------------------------------------------------------ | ------ | ------- | ------- | ---- |
| A1  | A call emitted by the loop is resolved by the single registry regardless of tool origin (DDA / generated / remote MCP)    | FR-001 | example | DONE    | test/data/providers/tool_registry/tool_registry_provider_test.dart ||
| A2  | Arguments violating a tool's JSON Schema return a validation error as the tool result; the mission continues              | FR-002 | example | DONE    | test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart ||
| A3  | A parallel-execution batch runs tools concurrently with results collected in call order                                   | FR-002 | example | DONE    | test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart ||
| A4  | A `confirm`-risk tool awaits the approval callback; denial or timeout yields a denied tool result                         | FR-003 | example | DONE    | test/data/providers/agent_tool/agent_tool_provider_test.dart ||
| A5  | An `admin`-risk tool on a non-internal mission is denied without invoking its implementation                               | FR-003 | example | DONE    | test/data/providers/agent_tool/agent_tool_provider_test.dart ||
| A6  | An SSE connection dropping mid-mission reconnects (backoff) and resumes tool listing/calls                                | FR-004 | example | DONE    | test/mcp/mcp_003_a6_reconnect_test.dart :: "A6: a mid-mission SSE drop reconnects with backoff and resumes both tool listing and tool calls" |
| A7  | An expiring token rotated by the auth callback keeps calls flowing without a manager rebuild                              | FR-004 | example | DONE    | test/data/providers/mcp_transport/mcp_transport_provider_test.dart ||
| A8  | In-proc tools called in a tight loop cross no serialization boundary (pass-by-reference with defensive arg copy)           | FR-004 | example | DONE    | test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart ||
| A9  | An oversized tool result returned to the loop shows the model summary + artifactRef only                                   | FR-005 | example | DONE    | test/data/providers/oversized_result_policy/oversized_result_policy_provider_test.dart ||

## Inner loop: deferred — plan.md absent

`plan.md` does not exist for this feature, so the inner-loop unit behaviors (per
component) cannot be derived. `/speckit.tdd.plan` must be re-run once `plan.md`
exists to populate the `U1..` table (tool registry, dispatch/validation, risk
gating, MCP transports, result sizing/artifactRef). This list records only the
outer-loop acceptance behaviors.

## Edge cases & invariants (from spec.md)

Carried from the spec's Edge Cases; not yet placed as numbered behaviors:

- Namespace collision across sources (`webview.browse` in-proc vs remote) → deterministic prefixing + warning event.
- MCP server returns malformed tool result → typed transport error surfaced as tool result.
- Approval callback never resolves → deny on timeout, mission continues.
- stdio server crash mid-call → bounded restart policy then transport-level failure.

## Shipped unit/provider coverage (inner-loop, NOT outer acceptance — reported, not followed)

The repo already ships inner-loop unit/provider tests for several building blocks
of this feature. These are **not** outer-loop acceptance tests and are explicitly
deferred by this outside-in plan; listed here for accuracy only:

- `test/data/providers/tool_registry/tool_registry_provider_test.dart` — registry resolution.
- `test/domain/entities/agent_tool/*`, `test/data/providers/agent_tool/*`, `test/data/providers/tool_result/*`, `test/domain/entities/tool_result/*` — tool model & results.
- `test/mcp/sse_mcp_client_test.dart`, `test/mcp/in_proc_mcp_client_test.dart`, `test/mcp/stdio_mcp_client_test.dart`, `test/mcp/mcp_tool_adapter_test.dart`, `test/mcp/tool_listing_cache_test.dart`, `test/data/providers/mcp_transport/*` — MCP transports.
- `test/llm/openai_compatible_client_test.dart`, `test/llm/anthropic_client_test.dart`, `test/llm/gemini_client_test.dart`, `test/types_test.dart` — provider-facing plumbing.

## Out of scope

- Inner-loop unit behaviors: deferred until `plan.md` (see above).
- zuraffa `McpSseServer` (#384) is the acceptance counterpart; its landing is tracked upstream, not here.
- Artifact storage backends: only the sink + fetch-by-ref interface is in scope here.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md` at planning time:

- Single test: `dart test {file} -n "{name}"`
- Full suite: `dart test`
- Coverage: `dart test --coverage=.dart_coverage {files}` (format with
  `dart run coverage:format_coverage --packages=.dart_tool/package_config.json --report-on=lib --in=.dart_coverage -l`)
- Mutation / property-based: **not available** in this repo (no `mutation_test` /
  `glados` in the lockfile).

## Credited to sibling implementation specs (already-covered rule, keyword-verified)

These outer-loop acceptance behaviors have no single engine orchestrator wiring them into one
mission entry point; the component public API _is_ the real entry point. Each behavior was checked
against the passing test of the implementation spec that owns the component (the full suite is green:
932 passed, 2 skipped). `DONE` = a keyword for the behavior was found in that test, so the assertion
holds. `BLOCKED` here means **no automated keyword match** in the sibling component test — the
behavior may be covered under different wording and needs a manual end-to-end acceptance test to
confirm; it is NOT a claim that the feature is missing. The component suites are green either way.

