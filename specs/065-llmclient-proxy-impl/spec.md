# Feature Specification: Full LlmClient with Local Proxy Support

**Feature Branch**: `065-llmclient-proxy-impl`

**Created**: 2026-08-24

**Status**: Draft

**Input**: User description: "implement the full llmclient with local proxy support, check ~/.kimi-code/config.toml and you will see the active kilo.ai account with api key and proxy http://localhost:8890 and model tencent/hy3:free first verify it with a curl request and then implement llmclient fully working and then start actual integration testing of agent"

## Summary
Make the agent's `LlmClient` actually work end-to-end: a real, configurable chat-completion client that calls an OpenAI-compatible gateway (kilo.ai) and routes all traffic through a local HTTP proxy (`http://localhost:8890`). The existing `LlmClient` value object, `LlmClientService`, and `LlmClientProvider` are scaffolded stubs (`current()`/`count()` throw `UnimplementedError`); this feature replaces them with a working implementation plus a real HTTP transport and a live integration test. Verified prerequisite: a `curl` POST to `https://api.kilo.ai/api/gateway/chat/completions` through the proxy with the `key7` bearer token returned a valid OpenAI-format completion (`HTTP 200`, model `tencent/hy3`, content `PONG`, ~4.8s). This advances epic issue #5 (Providers & Fallback) and unblocks real agent integration testing.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Real completion through the local proxy (Priority: P1)

The agent sends a chat-completion request to the configured gateway and receives a parsed completion, with all traffic leaving the machine through the local proxy.

**Why this priority**: This is the core capability the user explicitly asked for ("implement llmclient fully working") and is the prerequisite for any agent behavior.

**Independent Test**: Run the integration test (guarded on proxy reachability) that performs one live `chat/completions` call via the proxy and asserts a non-empty assistant message with usage metadata.

**Acceptance Scenarios**:

1. **Given** a configured provider with `base_url`, a bearer `api_key`, a `proxy_url`, and a `model`, **When** the client sends a chat-completion request, **Then** the request is routed through `proxy_url` and a `200` response with a non-empty assistant message is returned.
2. **Given** the proxy is reachable and the gateway returns a valid completion, **When** the response is parsed, **Then** the assistant content, any reasoning/thinking text, finish reason, and token usage are all exposed.
3. **Given** the proxy is unreachable, **When** a request is attempted, **Then** the failure is surfaced as a typed error and the integration test skips rather than failing the suite.

---

### User Story 2 - Config-driven client resolution (Priority: P2)

The `LlmClient` data layer resolves the active client (provider, base URL, API key, proxy URL, model, capabilities) from provider configuration instead of throwing.

**Why this priority**: Turns the scaffolded `LlmClientProvider` into a usable source of truth the engine can consume; keeps the system config-driven rather than hard-coded.

**Independent Test**: A unit test constructs the provider from a fixture config and asserts `current()` returns an `LlmClient` whose `providerName`, `model`, and capability flags match the active provider entry.

**Acceptance Scenarios**:

1. **Given** provider configuration containing an active kilo provider with `proxy_url` and model `tencent/hy3:free`, **When** `current()` is called, **Then** it returns an `LlmClient` describing that provider and no longer throws.
2. **Given** provider configuration, **When** `count()` is called, **Then** it returns the number of configured/usable clients without error.

---

### User Story 3 - Streaming support where advertised (Priority: P3)

When the resolved client reports `supportsStreaming`, the client can consume streamed (SSE) completions.

**Why this priority**: Nice-to-have for responsiveness; non-blocking and only relevant once the base client works.

**Independent Test**: A unit test feeds a canned SSE byte stream and asserts incremental content deltas are emitted and reassembled into the final message.

**Acceptance Scenarios**:

1. **Given** a streaming-capable client, **When** a streaming request is made, **Then** content arrives as deltas and the final assembled message equals the non-streaming equivalent.

---

### Edge Cases

- Proxy unreachable / connection refused → typed error, integration test skips.
- Gateway returns non-200 (e.g., 401 invalid token, 429 rate limit, 5xx) → error surfaced with status and body, no partial parse.
- Response missing `choices` or `message.content` → treated as a malformed/empty completion error, not a crash.
- `proxy_url` empty/undefined → client connects directly (no proxy), preserving non-proxied environments.
- Very large completion / thinking tokens → usage and content parsed without truncation.
- Request payload must not log the API key (secrets hygiene).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide an LLM client that sends a chat-completion request to a configured OpenAI-compatible gateway and returns a parsed completion.
- **FR-002**: The client MUST route outbound requests through a configurable local HTTP proxy (`proxy_url`) when one is configured, and connect directly when none is set.
- **FR-003**: The client MUST authenticate using a bearer API key sourced from provider configuration.
- **FR-004**: The client MUST accept and forward a target model identifier in the request.
- **FR-005**: The client MUST parse and expose the assistant message content, reasoning/thinking text, finish reason, and token usage from the gateway response.
- **FR-006**: The `LlmClient` data layer MUST resolve the active client (provider, base URL, API key reference, proxy URL, model, capability flags) from configuration instead of throwing `UnimplementedError`.
- **FR-007**: The implementation MUST respect the engine runtime `dart:io` purity gate — any transport using platform I/O MUST be confined to a consciously allowlisted I/O adapter (Constitution VII).
- **FR-008**: The system MUST include an integration test that performs a real completion through the proxy and asserts a valid, non-empty response; the test MUST skip gracefully when the proxy is unreachable.
- **FR-009**: Unit tests MUST cover request construction, proxy selection, and response parsing without any network access.
- **FR-010**: The client SHOULD support streamed (SSE) completions when the resolved client advertises `supportsStreaming`.

### Key Entities

- **LlmClient** (existing value object): `id`, `providerName`, `model`, `supportsStreaming`, `supportsThinking` — becomes resolvable from provider config.
- **ProviderConfig** (existing value object): `id`, `providerKind`, `baseUrl`, `models`, `timeoutMs` — the serializable config snapshot; the transport's secrets (`apiKey`) and egress (`proxyUrl`) are injected at construction rather than stored on the value object.
- **ChatMessage / ChatCompletion** (new value objects): request messages (role + content) and a parsed response (content, reasoning, finishReason, usage).
- **LlmTransport** (new): the I/O boundary that performs the HTTP call through the proxy and parses the response; the only component permitted to touch platform I/O.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A live call through the configured proxy returns a valid completion (pre-verified: `HTTP 200`, model `tencent/hy3`, content `PONG`, ~4.8s round-trip).
- **SC-002**: 100% of integration-test completions against the configured proxy return non-empty assistant content with token-usage metadata.
- **SC-003**: The `dart:io` purity gate passes in CI — platform I/O is confined to allowlisted adapters.
- **SC-004**: Unit tests cover request construction, proxy selection, and response parsing with zero network access; `dart analyze --fatal-infos` is clean; all pre-existing + new tests pass.
- **SC-005**: The `LlmClient` data layer no longer throws `UnimplementedError` for `current()`/`count()`.
- **SC-006**: The agent can be driven end-to-end through the real client (integration test exercises a full request/response cycle via the proxy).

## Assumptions

- The local proxy at `http://localhost:8890` is the egress for kilo.ai; configuration supplies `proxy_url`.
- The kilo.ai gateway is OpenAI-compatible at `{base_url}/chat/completions` and accepts a bearer JWT (verified with the `key7` token).
- Active provider = `kilo`, active key = `key7`, target model = `tencent/hy3:free` (responds as `tencent/hy3`).
- Full engine-loop orchestration (specs 002/045) is a separate effort; this feature delivers the working client, its transport, and a real integration test — not the turn-execution loop itself.
- The transport's platform-I/O boundary will be added to the `dart:io` allowlist with a written justification (Constitution VII), or implemented via a `dart:io`-free HTTP dependency if one satisfies the proxy requirement — decided at plan time.
- Model/provider details come from the existing `LlmClient`/`ProviderConfig` value objects (hand-curated plain Dart), consistent with the established pattern for issue #5 specs.
