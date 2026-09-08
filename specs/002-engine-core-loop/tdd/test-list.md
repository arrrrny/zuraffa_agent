# Test List: 002-engine-core-loop

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | the engine dispatches each call, appends result messages, and re-invokes the LLM until a non-tool finish reason. | AC-1 | PENDING |
| A2 | it completes without state corruption or event loss. | AC-2 | PENDING |
| A3 | the event stream is byte-identical (determinism). | AC-3 | PENDING |
| A4 | the assistant message carries thinking blocks next to tool calls. | AC-4 | PENDING |
| A5 | prior turns' thinking blocks are present. | AC-5 | PENDING |
| A6 | it is injected before the next LLM call. | AC-6 | PENDING |
| A7 | the loop continues with the follow-ups instead of exiting. | AC-7 | PENDING |
| A8 | the mission ends with a `MaxTurnsExceeded` outcome after turn 5. | AC-8 | PENDING |
| A9 | `LoopDetected` fires and the mission aborts cleanly. | AC-9 | PENDING |
| A10 | consumers receive them in order with monotonic turn/sequence identifiers. | AC-10 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | The engine MUST implement a turn-based while-loop advancing on LLM finish-reason, with no external state machine. | FR-001 | PENDING |
| U2 | Assistant messages MUST carry thinking blocks alongside tool calls; context assembly MUST preserve them across turns. | FR-002 | PENDING |
| U3 | The engine MUST support steering and follow-up message queues injected between turns. | FR-003 | PENDING |
| U4 | The engine MUST enforce max-turns, wall-clock timeout, and repetition-detection aborts with typed outcome events. | FR-004 | PENDING |
| U5 | The engine MUST emit every lifecycle event as a typed, ordered stream with sequence identifiers. | FR-005 | PENDING |
| U6 | The loop design MUST follow pi-mono's `agent-loop.ts` reference (turn-based, injectable behavior callbacks); pi_agent's loop stub is completed, not kept. | FR-006 | PENDING |

## Key entities

| entity | fields |
| ------ | ------ |
| EngineLoop |  |
| EngineEvent |  |
| StopPolicy |  |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 26]
route: A2 -> acceptance lane [declared: type marker, spec line 28]
route: A3 -> acceptance lane [declared: type marker, spec line 30]
route: A4 -> acceptance lane [declared: type marker, spec line 43]
route: A5 -> acceptance lane [declared: type marker, spec line 45]
route: A6 -> acceptance lane [declared: type marker, spec line 58]
route: A7 -> acceptance lane [declared: type marker, spec line 60]
route: A8 -> acceptance lane [declared: type marker, spec line 73]
route: A9 -> acceptance lane [declared: type marker, spec line 75]
route: A10 -> acceptance lane [declared: type marker, spec line 88]
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U6 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

