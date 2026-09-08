# Traceability: 002-engine-core-loop

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:27b04e2f3472fc1c4897e936d4af3106627f2153fac7c468af418c68a1eb566b
statements: 16
automated: 16
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 25 | 1. **Given** a mission with tools available, **When** the LLM returns `tool_calls`, **Then** the engine dispatches each call, appends result messages, and re-invokes the LLM until a non-tool finish reason. | A1 | automated |
| AC-2 | 27 | 2. **Given** a scripted 200-call mission, **When** executed, **Then** it completes without state corruption or event loss. | A2 | automated |
| AC-3 | 29 | 3. **Given** the same inputs and a recorded LLM, **When** re-run 10×, **Then** the event stream is byte-identical (determinism). | A3 | automated |
| AC-4 | 42 | 4. **Given** a provider streaming thinking deltas, **When** a turn completes, **Then** the assistant message carries thinking blocks next to tool calls. | A4 | automated |
| AC-5 | 44 | 5. **Given** a multi-turn mission, **When** turn N+1's context is assembled, **Then** prior turns' thinking blocks are present. | A5 | automated |
| AC-6 | 57 | 6. **Given** a running mission, **When** a steering message is enqueued, **Then** it is injected before the next LLM call. | A6 | automated |
| AC-7 | 59 | 7. **Given** follow-up messages queued at mission end, **When** the loop checks stop conditions, **Then** the loop continues with the follow-ups instead of exiting. | A7 | automated |
| AC-8 | 72 | 8. **Given** maxTurns=5, **When** the model never stops calling tools, **Then** the mission ends with a `MaxTurnsExceeded` outcome after turn 5. | A8 | automated |
| AC-9 | 74 | 9. **Given** identical repeated tool calls, **When** the threshold is hit, **Then** `LoopDetected` fires and the mission aborts cleanly. | A9 | automated |
| AC-10 | 87 | 10. **Given** any running mission, **When** events occur, **Then** consumers receive them in order with monotonic turn/sequence identifiers. | A10 | automated |
| FR-001 | 101 | - **FR-001**: The engine MUST implement a turn-based while-loop advancing on LLM finish-reason, with no external state machine. | U1 | automated |
| FR-002 | 102 | - **FR-002**: Assistant messages MUST carry thinking blocks alongside tool calls; context assembly MUST preserve them across turns. | U2 | automated |
| FR-003 | 103 | - **FR-003**: The engine MUST support steering and follow-up message queues injected between turns. | U3 | automated |
| FR-004 | 104 | - **FR-004**: The engine MUST enforce max-turns, wall-clock timeout, and repetition-detection aborts with typed outcome events. | U4 | automated |
| FR-005 | 105 | - **FR-005**: The engine MUST emit every lifecycle event as a typed, ordered stream with sequence identifiers. | U5 | automated |
| FR-006 | 106 | - **FR-006**: The loop design MUST follow pi-mono's `agent-loop.ts` reference (turn-based, injectable behavior callbacks); pi_agent's loop stub is completed, not kept. | U6 | automated |

