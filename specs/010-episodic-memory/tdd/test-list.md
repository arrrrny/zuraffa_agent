# Test List: 010-episodic-memory

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | an EpisodicMemory entry is created with the XML snapshot and original messages. [AC-1] | AC-1 | PENDING |
| A2 | memory summaries are available for retrieval (AgentMessageHistory carries messages + episodicMemories). [AC-2] | AC-2 | PENDING |
| A3 | the store holds exactly 3 entries whose combined original messages cover the full compressed history. [AC-3] | AC-3 | PENDING |
| A4 | the specific memory is returned — with its original messages, not just the summary. [AC-4] | AC-4 | PENDING |
| A5 | paginated results are returned. [AC-5] | AC-5 | PENDING |
| A6 | memories are restored. [AC-3 — the persistence half] | AC-6 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | Compression events MUST create EpisodicMemory entries. *(already green from spec 009's U8/U11 — this spec pins it with a multi-compression acceptance test rather than re-implementing)* | FR-001 | PENDING |
| U2 | A `retrieve_memory` tool MUST expose episodic memories to the model. | FR-002 | PENDING |
| U3 | EpisodicMemory MUST store both the summary (XML) and original messages. *(entity exists from spec 009; unchanged)* | FR-003 | PENDING |
| U4 | Retrieval MUST support snapshot_id lookup and limit/offset pagination. | FR-004 | PENDING |
| U5 | EpisodicMemory MUST persist via the session storage backend. | FR-005 | PENDING |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 26]
route: A2 -> acceptance lane [declared: type marker, spec line 28]
route: A3 -> acceptance lane [declared: type marker, spec line 30]
route: A4 -> acceptance lane [declared: type marker, spec line 43]
route: A5 -> acceptance lane [declared: type marker, spec line 45]
route: A6 -> acceptance lane [declared: type marker, spec line 58]
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

