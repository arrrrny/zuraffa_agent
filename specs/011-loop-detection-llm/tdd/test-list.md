# Test List: 011-loop-detection-llm

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | a loop is detected (isLoop=true, reason "tool_call_loop", confidence 1.0) and the mission should stop. [AC-1] | AC-1 | PENDING |
| A2 | the streak resets and no loop is detected from the earlier run. [AC-2] | AC-2 | PENDING |
| A3 | they do not reset the streak (a call→result→call→result chain still accumulates). [AC-3] | AC-3 | PENDING |
| A4 | an LLM diagnosis is triggered (exactly one LLM call at the boundary). [AC-4] | AC-4 | PENDING |
| A5 | the loop is detected and the mission stops. [AC-5] | AC-5 | PENDING |
| A6 | the mission continues normally (no detection). [AC-6] | AC-6 | PENDING |
| A7 | the configured thresholds are used. [AC-1/AC-4/AC-6 with non-default settings] | AC-7 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | The engine MUST detect tool call loops by tracking recent call signatures. | FR-001 | PENDING |
| U2 | The engine MUST detect cognitive stagnation via periodic LLM diagnosis. | FR-002 | PENDING |
| U3 | LLM diagnosis MUST be triggered after a configurable number of turns. | FR-003 | PENDING |
| U4 | Stagnation detection MUST use a confidence threshold (default 0.8). | FR-004 | PENDING |
| U5 | Detection parameters MUST be configurable. | FR-005 | PENDING |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 26]
route: A2 -> acceptance lane [declared: type marker, spec line 28]
route: A3 -> acceptance lane [declared: type marker, spec line 30]
route: A4 -> acceptance lane [declared: type marker, spec line 43]
route: A5 -> acceptance lane [declared: type marker, spec line 45]
route: A6 -> acceptance lane [declared: type marker, spec line 47]
route: A7 -> acceptance lane [declared: type marker, spec line 60]
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

