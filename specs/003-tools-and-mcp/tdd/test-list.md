# Test List: 003-tools-and-mcp

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | the registry resolves it regardless of origin. | AC-1 | PENDING |
| A2 | a validation error returns as the tool result (mission continues). | AC-2 | PENDING |
| A3 | tools run concurrently with results collected in call order. | AC-3 | PENDING |
| A4 | execution awaits the approval callback; denial or timeout yields a denied tool result. | AC-4 | PENDING |
| A5 | it is denied without invoking the implementation. | AC-5 | PENDING |
| A6 | the client reconnects (backoff) and resumes tool listing/calls. | AC-6 | PENDING |
| A7 | calls continue without manager rebuild. | AC-7 | PENDING |
| A8 | no serialization boundary exists (pass-by-reference with defensive arg copy). | AC-8 | PENDING |
| A9 | the model sees summary + artifactRef only. | AC-9 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | One tool registry MUST serve DDA, generated, and remote-MCP tools in a single namespace. | FR-001 | PENDING |
| U2 | Tool dispatch MUST validate arguments against JSON Schema and support sequential/parallel modes. | FR-002 | PENDING |
| U3 | `safe|confirm|admin` risk MUST be first-class tool metadata; dispatch MUST enforce approval/permission semantics. | FR-003 | PENDING |
| U4 | The MCP client MUST implement in-proc, SSE+Bearer (reconnect, auth callback), and stdio transports. | FR-004 | PENDING |
| U5 | Oversized results MUST be summarized + artifactRef'd before entering model context. | FR-005 | PENDING |

## Key entities

| entity | fields |
| ------ | ------ |
| AgentTool |  |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 26]
route: A2 -> acceptance lane [declared: type marker, spec line 28]
route: A3 -> acceptance lane [declared: type marker, spec line 30]
route: A4 -> acceptance lane [declared: type marker, spec line 43]
route: A5 -> acceptance lane [declared: type marker, spec line 45]
route: A6 -> acceptance lane [declared: type marker, spec line 58]
route: A7 -> acceptance lane [declared: type marker, spec line 60]
route: A8 -> acceptance lane [declared: type marker, spec line 62]
route: A9 -> acceptance lane [declared: type marker, spec line 75]
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

