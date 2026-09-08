# Test List: 005-subagents-and-declarative

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | it runs with its own session (spec 002 tree), allowlist, and budget. | AC-1 | PENDING |
| A2 | the parent context receives the result summary only. | AC-2 | PENDING |
| A3 | the parent receives a typed failure result and continues. | AC-3 | PENDING |
| A4 | its session tree continues from the stored leaf. | AC-4 | PENDING |
| A5 | B inherits unspecified fields and overrides specified ones. | AC-5 | PENDING |
| A6 | it fails validation with a precise error. | AC-6 | PENDING |
| A7 | agent behavior changes with no code change. | AC-7 | PENDING |
| A8 | the engine creates/resumes the instance and awaits its result. | AC-8 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | The engine MUST support named sub-agent types with isolated contexts, tool allowlists, and budgets. | FR-001 | PENDING |
| U2 | Sub-agent instances MUST persist and be resumable across engine restarts. | FR-002 | PENDING |
| U3 | Agent definitions MUST be expressible as declarative YAML specs with `extends` inheritance and validation diagnostics. | FR-003 | PENDING |
| U4 | A built-in dispatch tool MUST expose sub-agent delegation to the model. | FR-004 | PENDING |
| U5 | Context isolation MUST guarantee parent receives result summaries only. | FR-005 | PENDING |

## Key entities

| entity | fields |
| ------ | ------ |
| SubAgentType |  |
| AgentSpec |  |
| DispatchTool |  |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 26]
route: A2 -> acceptance lane [declared: type marker, spec line 28]
route: A3 -> acceptance lane [declared: type marker, spec line 30]
route: A4 -> acceptance lane [declared: type marker, spec line 43]
route: A5 -> acceptance lane [declared: type marker, spec line 56]
route: A6 -> acceptance lane [declared: type marker, spec line 58]
route: A7 -> acceptance lane [declared: type marker, spec line 60]
route: A8 -> acceptance lane [declared: type marker, spec line 73]
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

