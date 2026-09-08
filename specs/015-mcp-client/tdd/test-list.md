# Test List: 015-mcp-client

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | it executes without serialization overhead. | AC-1 | PENDING |
| A2 | the client reconnects and resumes. | AC-2 | PENDING |
| A3 | calls continue without rebuild. | AC-3 | PENDING |
| A4 | the client reconnects automatically. | AC-4 | PENDING |
| A5 | they are registered in the tool registry. | AC-5 | PENDING |
| A6 | the cache is invalidated and tools are re-listed. | AC-6 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | The MCP client MUST implement in-proc, SSE+Bearer, and stdio transports. | FR-001 | PENDING |
| U2 | SSE transport MUST support automatic reconnect with exponential backoff. | FR-002 | PENDING |
| U3 | SSE transport MUST support auth callback for token rotation. | FR-003 | PENDING |
| U4 | stdio transport MUST handle process crashes with bounded retries. | FR-004 | PENDING |
| U5 | Tool listing MUST be cached and invalidated on change notifications. | FR-005 | PENDING |

## Key entities

| entity | fields |
| ------ | ------ |
| McpClient |  |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 26]
route: A2 -> acceptance lane [declared: type marker, spec line 39]
route: A3 -> acceptance lane [declared: type marker, spec line 41]
route: A4 -> acceptance lane [declared: type marker, spec line 54]
route: A5 -> acceptance lane [declared: type marker, spec line 67]
route: A6 -> acceptance lane [declared: type marker, spec line 69]
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

