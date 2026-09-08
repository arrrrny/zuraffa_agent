# Traceability: 065-llmclient-proxy-impl

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:34c0f57147f69e3735e2cdd78980480d649eccc9fde4b99832d8f41a915eb08d
statements: 16
automated: 16
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 28 | 1. **Given** a configured provider with `base_url`, a bearer `api_key`, a `proxy_url`, and a `model`, **When** the client sends a chat-completion request, **Then** the request is routed through `proxy_url` and a `200` response with a non-empty assistant message is returned. | A1 | automated |
| AC-2 | 30 | 2. **Given** the proxy is reachable and the gateway returns a valid completion, **When** the response is parsed, **Then** the assistant content, any reasoning/thinking text, finish reason, and token usage are all exposed. | A2 | automated |
| AC-3 | 32 | 3. **Given** the proxy is unreachable, **When** a request is attempted, **Then** the failure is surfaced as a typed error and the integration test skips rather than failing the suite. | A3 | automated |
| AC-4 | 47 | 4. **Given** provider configuration containing an active kilo provider with `proxy_url` and model `tencent/hy3:free`, **When** `current()` is called, **Then** it returns an `LlmClient` describing that provider and no longer throws. | A4 | automated |
| AC-5 | 49 | 5. **Given** provider configuration, **When** `count()` is called, **Then** it returns the number of configured/usable clients without error. | A5 | automated |
| AC-6 | 64 | 6. **Given** a streaming-capable client, **When** a streaming request is made, **Then** content arrives as deltas and the final assembled message equals the non-streaming equivalent. | A6 | automated |
| FR-001 | 82 | - **FR-001**: The system MUST provide an LLM client that sends a chat-completion request to a configured OpenAI-compatible gateway and returns a parsed completion. | U1 | automated |
| FR-002 | 83 | - **FR-002**: The client MUST route outbound requests through a configurable local HTTP proxy (`proxy_url`) when one is configured, and connect directly when none is set. | U2 | automated |
| FR-003 | 84 | - **FR-003**: The client MUST authenticate using a bearer API key sourced from provider configuration. | U3 | automated |
| FR-004 | 85 | - **FR-004**: The client MUST accept and forward a target model identifier in the request. | U4 | automated |
| FR-005 | 86 | - **FR-005**: The client MUST parse and expose the assistant message content, reasoning/thinking text, finish reason, and token usage from the gateway response. | U5 | automated |
| FR-006 | 87 | - **FR-006**: The `LlmClient` data layer MUST resolve the active client (provider, base URL, API key reference, proxy URL, model, capability flags) from configuration instead of throwing `UnimplementedError`. | U6 | automated |
| FR-007 | 88 | - **FR-007**: The implementation MUST respect the engine runtime `dart:io` purity gate — any transport using platform I/O MUST be confined to a consciously allowlisted I/O adapter (Constitution VII). | U7 | automated |
| FR-008 | 89 | - **FR-008**: The system MUST include an integration test that performs a real completion through the proxy and asserts a valid, non-empty response; the test MUST skip gracefully when the proxy is unreachable. | U8 | automated |
| FR-009 | 90 | - **FR-009**: Unit tests MUST cover request construction, proxy selection, and response parsing without any network access. | U9 | automated |
| FR-010 | 91 | - **FR-010**: The system MUST satisfy this requirement: The client SHOULD support streamed (SSE) completions when the resolved client advertises `supportsStreaming`. | U10 | automated |

