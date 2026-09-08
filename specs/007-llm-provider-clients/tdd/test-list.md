# Test List: 007-llm-provider-clients

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | content deltas, tool call fragments, and usage parse correctly. [AC-1] | AC-1 | PENDING |
| A2 | it tolerates gracefully (empty map default). [AC-2] | AC-2 | PENDING |
| A3 | a typed error with status code and body is thrown. [AC-3] | AC-3 | PENDING |
| A4 | thinking blocks and content blocks parse correctly. [AC-4] | AC-4 | PENDING |
| A5 | they assemble from streamed argument fragments. [AC-5] | AC-5 | PENDING |
| A6 | JSON line chunks parse correctly. [AC-6] | AC-6 | PENDING |
| A7 | the client handles it gracefully. [AC-7] | AC-7 | PENDING |
| A8 | all providers produce identical event sequences, tool-call buffering, and usage fields. [AC-8] | AC-8 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | The engine MUST provide a unified `LlmClient` interface with `generate()` and `stream()` methods. | FR-001 | PENDING |
| U2 | OpenAI-compatible, Anthropic, and Gemini clients MUST implement this interface. | FR-002 | PENDING |
| U3 | All clients MUST support multimodal input (text, image, audio, document) and output. | FR-003 | PENDING |
| U4 | All clients MUST support streaming with tool call fragment assembly. | FR-004 | PENDING |
| U5 | All clients MUST track usage (input, output, cached, thought tokens). | FR-005 | PENDING |
| U6 | All clients MUST implement retry with exponential backoff for 429/5xx. | FR-006 | PENDING |
| U7 | All clients MUST be vendored from dart_agent_core with attribution; dart_agent_core MUST NOT appear in the dependency graph. | FR-007 | PENDING |

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
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U6 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U7 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

