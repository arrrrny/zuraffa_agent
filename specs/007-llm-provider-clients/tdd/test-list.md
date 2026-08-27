# Test List: LLM Provider Clients

---
feature: 007-llm-provider-clients
loop: outside-in
profile: .specify/memory/tdd-profile.md
spec_criteria: 8 # acceptance criteria AC-1..AC-8 in spec.md
planned_at: 3adcd04
updated_at: 9117fa2
suite_baseline: red # 8 pre-existing loading failures from other unimplemented features (see cycle-log baseline); green criterion for this feature = its tests pass AND full-suite delta vs baseline is 0 new failures
---

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`, through the feature's real entry point — each provider client's public `generate()`/`stream()` API over recorded fixtures (this is a library feature; the public API is the entry surface, and there is no separate acceptance runner, per the stack profile).

| id  | behavior                                                                                     | traces | kind    | state   | test |
| --- | -------------------------------------------------------------------------------------------- | ------ | ------- | ------- | ---- |
| A1  | OpenAI-compatible streaming emits content deltas, assembled tool calls, and usage, completing on `[DONE]` | AC-1   | example | DONE | `test/llm/llm_client_contract_test.dart::openai stream` + `openai_compatible_client_test.dart::U12` |
| A2  | A malformed OpenAI tool argument parses to an empty argument map instead of throwing        | AC-2   | example | DONE | `test/llm/openai_compatible_client_test.dart::U13` |
| A3  | A non-2xx OpenAI response raises LlmHttpException carrying statusCode and body              | AC-3   | example | DONE | `test/llm/openai_compatible_client_test.dart::U14` |
| A4  | Anthropic streaming emits thinking deltas, text deltas, and final usage/stop reason         | AC-4   | example | DONE | `test/llm/anthropic_client_test.dart::U16` + `contract suite::anthropic stream` |
| A5  | Anthropic tool calls assemble from streamed input_json_delta fragments                      | AC-5   | example | DONE | `test/llm/anthropic_client_test.dart::U17` |
| A6  | Gemini streaming parses JSON-line chunks into text and function-call parts, completing cleanly | AC-6   | example | DONE | `test/llm/gemini_client_test.dart::U20` + `contract suite::gemini stream` |
| A7  | A MALFORMED_FUNCTION_CALL Gemini finishReason surfaces gracefully without throwing          | AC-7   | example | DONE | `test/llm/gemini_client_test.dart::U21` |
| A8  | The shared contract suite passes identically for OpenAI, Anthropic, and Gemini fixtures     | AC-8   | contract | DONE | `test/llm/llm_client_contract_test.dart` (12 tests, 3 providers × 4 scenarios) |

## Inner loop: unit behaviors

### `lib/src/llm/llm_client.dart`

| id  | behavior                                                                                          | traces          | kind    | state   | test |
| --- | ------------------------------------------------------------------------------------------------- | --------------- | ------- | ------- | ---- |
| U1  | LlmUsage, LlmToolCall, LlmResponse, LlmResponseChunk are immutable value types exposing the spec'd fields with value equality | FR-001, FR-005 | example | DONE | `test/llm/llm_client_test.dart::U1` |
| U2  | LlmHttpException carries provider, statusCode, body, and a readable message                       | AC-3, FR-002    | example | DONE | `test/llm/llm_client_test.dart::U2` |

### `lib/src/llm/llm_transport.dart` (+ fake helper)

| id  | behavior                                                                                          | traces     | kind             | state   | test |
| --- | ------------------------------------------------------------------------------------------------- | ---------- | ---------------- | ------- | ---- |
| U3  | The transport seam round-trips a request to a status/headers/body response and to a line stream via the fixture-replaying fake | FR-001 (seam) | example | DONE | `test/llm/llm_transport_test.dart::U3` |

### `lib/src/llm/retry.dart` (+ `llm_clock.dart`)

| id  | behavior                                                                                          | traces     | kind    | state   | test |
| --- | ------------------------------------------------------------------------------------------------- | ---------- | ------- | ------- | ---- |
| U4  | A 429 then success is retried exactly once and succeeds (injected clock observes one backoff delay) | FR-006, AC-3 | example | DONE | `test/llm/retry_test.dart::U4` |
| U5  | A 5xx then success is retried and succeeds                                                        | FR-006     | example | DONE | `test/llm/retry_test.dart::U5` |
| U7  | A non-retryable 4xx is thrown immediately with zero retries                                       | FR-006     | example | DONE | `test/llm/retry_test.dart::U7` |
| U6  | Exhausted retries throw the last error after maxAttempts attempts                                 | FR-006     | example | DONE | `test/llm/retry_test.dart::U6` |
| U8  | Backoff delays grow exponentially and are capped; jitter is deterministic under a fixed seed      | FR-006     | example | DONE | `test/llm/retry_test.dart::U8` |
| U9  | A Retry-After header (seconds) overrides the computed backoff delay                               | FR-006     | example | DONE | `test/llm/retry_test.dart::U9` |

### `lib/src/llm/io_llm_transport.dart`

| id  | behavior                                                                                          | traces     | kind    | state   | test |
| --- | ------------------------------------------------------------------------------------------------- | ---------- | ------- | ------- | ---- |
| U10 | The dart:io adapter maps LlmHttpRequest onto HttpClient producing status, headers, body, and a decoded line stream | FR-001 (seam), constitution VII | example | DONE | `test/llm/io_llm_transport_test.dart::U10` |

### `lib/src/llm/openai_compatible_client.dart`

| id  | behavior                                                                                          | traces          | kind    | state   | test |
| --- | ------------------------------------------------------------------------------------------------- | --------------- | ------- | ------- | ---- |
| U11 | generate() builds the chat/completions body (model, messages incl. multimodal blocks, tools) and parses content, finishReason, and usage | FR-002, FR-003, FR-005 | example | DONE | `test/llm/openai_compatible_client_test.dart::U11` |
| U12 | stream() parses SSE data lines to content deltas; the final chunk carries usage; [DONE] yields isComplete | FR-004, FR-005 | example | DONE | `test/llm/openai_compatible_client_test.dart::U12` |
| U13 | Tool-call fragments assemble by index across chunks; malformed arguments default to an empty map  | FR-004, AC-2    | example | DONE | `test/llm/openai_compatible_client_test.dart::U13` |
| U14 | A non-2xx response raises LlmHttpException with statusCode and body                               | AC-3            | example | DONE | `test/llm/openai_compatible_client_test.dart::U14` |

### `lib/src/llm/anthropic_client.dart`

| id  | behavior                                                                                          | traces          | kind    | state   | test |
| --- | ------------------------------------------------------------------------------------------------- | --------------- | ------- | ------- | ---- |
| U15 | generate() builds the Messages body (system, messages, tools) and parses content blocks incl. thinking | FR-002, FR-003, FR-005 | example | DONE | `test/llm/anthropic_client_test.dart::U15` |
| U16 | stream() parses message_start (input usage), content_block_delta (text/thinking), and message_delta (stop reason, output usage) | FR-004, FR-005, AC-4 | example | DONE | `test/llm/anthropic_client_test.dart::U16` |
| U17 | tool_use blocks assemble from input_json_delta partial_json fragments                             | FR-004, AC-5    | example | DONE | `test/llm/anthropic_client_test.dart::U17` |
| U18 | A non-2xx response raises a typed error                                                           | AC-3 (analogue) | example | DONE | `test/llm/anthropic_client_test.dart::U18` |

### `lib/src/llm/gemini_client.dart`

| id  | behavior                                                                                          | traces          | kind    | state   | test |
| --- | ------------------------------------------------------------------------------------------------- | --------------- | ------- | ------- | ---- |
| U19 | generate() builds the generateContent body (contents/parts, tools) and parses text + usageMetadata (prompt, candidates, thoughts, cached) | FR-002, FR-003, FR-005 | example | DONE | `test/llm/gemini_client_test.dart::U19` |
| U20 | stream() parses JSONL chunks into text parts and function calls, completing cleanly               | FR-004, AC-6    | example | DONE | `test/llm/gemini_client_test.dart::U20` |
| U21 | A MALFORMED_FUNCTION_CALL finishReason surfaces in the response without throwing                  | AC-7            | example | DONE | `test/llm/gemini_client_test.dart::U21` |
| U22 | A non-2xx response raises a typed error                                                           | AC-3 (analogue) | example | DONE | `test/llm/gemini_client_test.dart::U22` |

## Invariants and edge cases still to place

- Empty SSE line / comment lines (`: keep-alive`) are skipped without emitting events (placed implicitly inside U12/U16 cycles — becomes its own behavior if it ever breaks).
- Stream errors mid-flight propagate as LlmHttpException and never emit a phantom isComplete chunk (covered by FallbackChainClient contract in spec 008; placed here only if a provider-specific divergence shows up).

## Out of scope

- Bedrock/Responses-API clients (dart_agent_core has 5 providers; this spec pins 3 — see spec.md US1–US3).
- Live-network integration tests (constitution: fixtures only).
- Fallback/health behavior on top of the clients — spec 008.
- The engine loop's consumption of clients — spec 002.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md`:

- Single test: `dart test {file} --name "{name}" --reporter expanded`
- Full suite: `dart test`
- Coverage: `dart test --coverage=coverage`
- Mutation: none installed — deliberate mutants per rubric
