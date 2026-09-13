# Test List: 065-llmclient-proxy-impl

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | the request is routed through `proxy_url` and a `200` response with a non-empty assistant message is returned. | AC-1 | PENDING |
| A2 | the assistant content, any reasoning/thinking text, finish reason, and token usage are all exposed. | AC-2 | PENDING |
| A3 | the failure is surfaced as a typed error and the integration test skips rather than failing the suite. | AC-3 | PENDING |
| A4 | it returns an `LlmClient` describing that provider and no longer throws. | AC-4 | PENDING |
| A5 | it returns the number of configured/usable clients without error. | AC-5 | PENDING |
| A6 | content arrives as deltas and the final assembled message equals the non-streaming equivalent. | AC-6 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | The system MUST provide an LLM client that sends a chat-completion request to a configured OpenAI-compatible gateway and returns a parsed completion. | FR-001 | PENDING |
| U2 | The client MUST route outbound requests through a configurable local HTTP proxy (`proxy_url`) when one is configured, and connect directly when none is set. | FR-002 | PENDING |
| U3 | The client MUST authenticate using a bearer API key sourced from provider configuration. | FR-003 | PENDING |
| U4 | The client MUST accept and forward a target model identifier in the request. | FR-004 | PENDING |
| U5 | The client MUST parse and expose the assistant message content, reasoning/thinking text, finish reason, and token usage from the gateway response. | FR-005 | PENDING |
| U6 | The `LlmClient` data layer MUST resolve the active client (provider, base URL, API key reference, proxy URL, model, capability flags) from configuration instead of throwing `UnimplementedError`. | FR-006 | PENDING |
| U7 | The implementation MUST respect the engine runtime `dart:io` purity gate — any transport using platform I/O MUST be confined to a consciously allowlisted I/O adapter (Constitution VII). | FR-007 | PENDING |
| U8 | The system MUST include an integration test that performs a real completion through the proxy and asserts a valid, non-empty response; the test MUST skip gracefully when the proxy is unreachable. | FR-008 | PENDING |
| U9 | Unit tests MUST cover request construction, proxy selection, and response parsing without any network access. | FR-009 | PENDING |
| U10 | The system MUST satisfy this requirement: The client SHOULD support streamed (SSE) completions when the resolved client advertises `supportsStreaming`. | FR-010 | PENDING |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 29]
route: A2 -> acceptance lane [declared: type marker, spec line 31]
route: A3 -> acceptance lane [declared: type marker, spec line 33]
route: A4 -> acceptance lane [declared: type marker, spec line 48]
route: A5 -> acceptance lane [declared: type marker, spec line 50]
route: A6 -> acceptance lane [declared: type marker, spec line 65]
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U6 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U7 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U8 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U9 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U10 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

