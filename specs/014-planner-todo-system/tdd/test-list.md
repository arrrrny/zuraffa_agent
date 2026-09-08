# Test List: 014-planner-todo-system

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | the plan state is updated. | AC-1 | PENDING |
| A2 | accurate counts are returned. | AC-2 | PENDING |
| A3 | planner tools are available but optional. | AC-3 | PENDING |
| A4 | planning is required before execution. | AC-4 | PENDING |
| A5 | the plan state is preserved. | AC-5 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | A `write_todos` tool MUST be injectable into the agent. | FR-001 | PENDING |
| U2 | Plan state MUST track steps with status (pending, in_progress, completed, cancelled). | FR-002 | PENDING |
| U3 | Plan mode MUST be configurable (none, auto, must). | FR-003 | PENDING |
| U4 | Plan state MUST persist across turns. | FR-004 | PENDING |
| U5 | Plan changes MUST emit PlanChangedEvent. | FR-005 | PENDING |

## Key entities

| entity | fields |
| ------ | ------ |
| Planner |  |
| PlanState |  |
| PlanStep |  |
| StepStatus |  |
| PlanMode |  |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 26]
route: A2 -> acceptance lane [declared: type marker, spec line 28]
route: A3 -> acceptance lane [declared: type marker, spec line 41]
route: A4 -> acceptance lane [declared: type marker, spec line 43]
route: A5 -> acceptance lane [declared: type marker, spec line 56]
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

