# Test List: 001-state-and-sessions

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | every turn, message, tool invocation, and usage record is a distinct typed entity retrievable independently by identity. | AC-1 | PENDING |
| A2 | each equals its pre-persistence value as a typed object — no untyped map escapes anywhere in the entity API. | AC-2 | PENDING |
| A3 | the new branch shares ancestry entries 1..N with the original and diverges cleanly after N; both branches remain resumable. | AC-3 | PENDING |
| A4 | `buildContext()` reconstructs each branch's conversation exactly — the original branch matches its pre-fork history, with no cross-contamination. | AC-4 | PENDING |
| A5 | the session resumes from its latest leaf. | AC-5 | PENDING |
| A6 | both yield the identical branch structure and entries (round-trip equivalence). | AC-6 | PENDING |
| A7 | decisions, tool names, key results, and plan state survive verbatim, and discarded verbose material is replaced by structured summaries that reference retrievable artifacts. | AC-7 | PENDING |
| A8 | mission outcomes are equal and context usage stays under the configured budget across the full 50+ tool calls. | AC-8 | PENDING |
| A9 | types/tools/session-tree/SSE/skills/templates carry attribution headers and pass the engine's test suite. | AC-9 | PENDING |
| A10 | no stub code ships — the live loop is delivered by spec 002 (engine core), not ported as a stub. | AC-10 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | State MUST be granular typed entities (session/message/turn/invocation/usage), defined through Zorphy per constitution IX — no monolithic blob, no untyped map escapes. | FR-001 | PENDING |
| U2 | Sessions MUST form a tree with first-class branch, fork, switch, and resume. | FR-002 | PENDING |
| U3 | Persistence MUST ship Hive (device) and JSONL (debug/CI) datasources behind one storage interface. | FR-003 | PENDING |
| U4 | Compaction MUST be selective and structured (retain/summarize/artifact-ref), never naive truncation. | FR-004 | PENDING |
| U5 | pi_agent assets MUST be merged with attribution; stubs replaced, not shipped. | FR-005 | PENDING |

## Key entities

| entity | fields |
| ------ | ------ |
| AgentMessage |  |
| TurnRecord |  |
| ToolInvocation |  |
| UsageLedger |  |

## External dependencies

| dependency | type | contract | mock priority |
| ---------- | ---- | -------- | ------------- |
| Hive | storage: declared external dependency, used by the implemented datasources | datasource contract per requirement statements | none |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A2 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A3 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A4 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A5 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A6 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A7 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A8 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A9 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A10 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

