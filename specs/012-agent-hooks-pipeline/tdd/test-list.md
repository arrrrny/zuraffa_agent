# Test List: 012-agent-hooks-pipeline

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | the hook is called at each point with the point's typed context. [AC-1] | AC-1 | PENDING |
| A2 | the modified request is what the pipeline hands back to the engine (and the engine's LlmClient receives it). [AC-2] | AC-2 | PENDING |
| A3 | a synthetic result is returned without executing the tool. [AC-3] | AC-3 | PENDING |
| A4 | both are called in registration order at every point. [AC-4] | AC-4 | PENDING |
| A5 | the run stops with a typed error (HookAbortError carrying the hook name and reason) and later hooks are not called. [AC-5] | AC-5 | PENDING |
| A6 | B observes A's modification (sequential fold). [AC-6] | AC-6 | PENDING |
| A7 | a synthetic result is returned and the tool is not executed. [AC-3 — same scenario pinned from the result side] | AC-7 | PENDING |
| A8 | the engine calls the LLM again. [AC-7] | AC-8 | PENDING |
| A9 | every point continues with the context unmodified (a bare hook is a no-op). [AC-8] | AC-9 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | The engine MUST support registering multiple hooks per lifecycle point. | FR-001 | PENDING |
| U2 | Hooks MUST be called in registration order at each lifecycle point. | FR-002 | PENDING |
| U3 | Each hook point MUST have typed context and result classes. | FR-003 | PENDING |
| U4 | Any hook MUST be able to abort the run with a typed error. | FR-004 | PENDING |
| U5 | Hooks MUST be able to modify model calls, tool calls, and tool results. | FR-005 | PENDING |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 26]
route: A2 -> acceptance lane [declared: type marker, spec line 28]
route: A3 -> acceptance lane [declared: type marker, spec line 30]
route: A4 -> acceptance lane [declared: type marker, spec line 43]
route: A5 -> acceptance lane [declared: type marker, spec line 45]
route: A6 -> acceptance lane [declared: type marker, spec line 47]
route: A7 -> acceptance lane [declared: type marker, spec line 60]
route: A8 -> acceptance lane [declared: type marker, spec line 62]
route: A9 -> acceptance lane [declared: type marker, spec line 64]
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

