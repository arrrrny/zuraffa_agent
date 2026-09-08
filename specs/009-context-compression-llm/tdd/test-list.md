# Test List: 009-context-compression-llm

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | an LLM generates a `<state_snapshot>` with sections: overall_goal, key_knowledge, file_system_state, recent_actions, current_plan. [AC-1] | AC-1 | PENDING |
| A2 | the snapshot is prepended as an episodic memory entry, and recent messages are preserved. [AC-2] | AC-2 | PENDING |
| A3 | the engine falls back to the heuristic summarizer. [AC-3] | AC-3 | PENDING |
| A4 | the snapshot is returned with its original messages. [AC-4] | AC-4 | PENDING |
| A5 | compression triggers at the configured point. [AC-5] | AC-5 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | The engine MUST compress conversation history when token threshold is exceeded. | FR-001 | PENDING |
| U2 | Compression MUST use an LLM to generate a structured XML snapshot. | FR-002 | PENDING |
| U3 | Compressed messages MUST become EpisodicMemory entries. | FR-003 | PENDING |
| U4 | Recent messages MUST be preserved verbatim after compression. | FR-004 | PENDING |
| U5 | The engine MUST fall back to heuristic summarization on LLM failure. | FR-005 | PENDING |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 26]
route: A2 -> acceptance lane [declared: type marker, spec line 28]
route: A3 -> acceptance lane [declared: type marker, spec line 30]
route: A4 -> acceptance lane [declared: type marker, spec line 43]
route: A5 -> acceptance lane [declared: type marker, spec line 56]
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

