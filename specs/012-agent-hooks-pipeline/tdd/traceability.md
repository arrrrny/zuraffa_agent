# Traceability: 012-agent-hooks-pipeline

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:8b94d75cdba6505a87b9e350cf87a59d5a5974696284ec2f8c0fc1b16598a229
statements: 14
automated: 14
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 25 | 1. **Given** a registered hook, **When** the pipeline runs the 9 lifecycle points, **Then** the hook is called at each point with the point's typed context. **[AC-1]** | A1 | automated |
| AC-2 | 27 | 2. **Given** a hook that modifies the model call, **When** beforeModelCall fires, **Then** the modified request is what the pipeline hands back to the engine (and the engine's LlmClient receives it). **[AC-2]** | A2 | automated |
| AC-3 | 29 | 3. **Given** a hook that denies a tool call, **When** beforeToolCall fires, **Then** a synthetic result is returned without executing the tool. **[AC-3]** | A3 | automated |
| AC-4 | 42 | 4. **Given** two hooks, **When** the pipeline runs, **Then** both are called in registration order at every point. **[AC-4]** | A4 | automated |
| AC-5 | 44 | 5. **Given** a hook that aborts, **When** it fires, **Then** the run stops with a typed error (HookAbortError carrying the hook name and reason) and later hooks are not called. **[AC-5]** | A5 | automated |
| AC-6 | 46 | 6. **Given** hook A modifies the context, **When** hook B runs after it, **Then** B observes A's modification (sequential fold). **[AC-6]** | A6 | automated |
| AC-7 | 59 | 7. **Given** a beforeToolCall hook returning deny, **When** the tool call reaches the hook, **Then** a synthetic result is returned and the tool is not executed. **[AC-3 — same scenario pinned from the result side]** | A7 | automated |
| AC-8 | 61 | 8. **Given** an afterModelCall hook returning retry, **When** the hook fires, **Then** the engine calls the LLM again. **[AC-7]** | A8 | automated |
| AC-9 | 63 | 9. **Given** default (un-overridden) hook methods, **When** the pipeline runs, **Then** every point continues with the context unmodified (a bare hook is a no-op). **[AC-8]** | A9 | automated |
| FR-001 | 70 | - **FR-001**: The engine MUST support registering multiple hooks per lifecycle point. | U1 | automated |
| FR-002 | 71 | - **FR-002**: Hooks MUST be called in registration order at each lifecycle point. | U2 | automated |
| FR-003 | 72 | - **FR-003**: Each hook point MUST have typed context and result classes. | U3 | automated |
| FR-004 | 73 | - **FR-004**: Any hook MUST be able to abort the run with a typed error. | U4 | automated |
| FR-005 | 74 | - **FR-005**: Hooks MUST be able to modify model calls, tool calls, and tool results. | U5 | automated |

