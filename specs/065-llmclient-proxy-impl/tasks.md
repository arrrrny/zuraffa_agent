# Tasks: Full LlmClient with Local Proxy Support (spec 065)

Feature branch: `tdd/065-llmclient-proxy-impl`. Tests are mandatory and must be
observed failing before their implementation task starts (Constitution XI, pending
ratification). Implementation of every behavior is already complete (merged via PR
#71); this file records the test list as tasks and flags the two unit gaps the TDD
loop must still close.

## Story 1 — Real completion through the local proxy (P1)

- [x] [U1] Test: request body build with messages + model (`llm_http_transport_test.dart`)
- [x] [U2] Test: stream flag honored in request body (`llm_http_transport_test.dart`)
- [x] [U3] Test/Integ: route through proxy via `HttpClient.findProxy` when `proxyUrl` set (`llm_client_proxy_test.dart`)
- [x] [U4] Test: connect directly (no `findProxy`) when `proxyUrl` is empty/null
- [x] [U5] Test: parse content, reasoning, finishReason, usage (`llm_http_transport_test.dart`)
- [x] [U6] Test: reassemble reasoning from `reasoning_details` when absent (`llm_http_transport_test.dart`)
- [x] [U7] Test: throw on missing `choices` (`llm_http_transport_test.dart`)
- [x] [U8] Test: throw on empty `content` (`llm_http_transport_test.dart`)
- [x] Impl (PR #71): `LlmHttpTransport` request-build, proxy routing, response parse, error paths
- [x] [A1] Gate: Story 1 acceptance test (`performs a real completion through the proxy`) green before story complete

## Story 2 — Config-driven client resolution (P2)

- [x] [U9] Test: `current()` returns active `LlmClient` from config, not stubbed (`llm_client_provider_test.dart`)
- [x] [U10] Test: `count()` returns number of usable clients (`llm_client_provider_test.dart`)
- [x] [U12] Test: `LlmClient` equality is value-based across all fields (`llm_client_provider_test.dart`)
- [ ] [U11] Test: `ProviderConfig.timeoutMs` forwarded to the transport's completion call
- [x] Impl (PR #71): `LlmClientProvider` resolves from provider configuration
- [x] [A2] Gate: Story 2 acceptance test (`provider resolves the active client from config`) green before story complete

## Story 3 — Streaming support where advertised (P3)

- [x] [U13] Test: `ChatMessage`/`ChatCompletion`/`LlmUsage`/`LlmResponse`/`LlmResponseChunk` are value types with spec-exact fields (`llm_client_test.dart`)
- [x] [U14] Test: `LlmHttpException` carries provider, status, body, readable message (`llm_client_test.dart`)
- [x] [U15] Test: `generate()` returns canonical content, usage, finish reason (`llm_client_contract_test.dart`)
- [x] [U16] Test: non-2xx raises `LlmHttpException` with status + body, no partial parse (`llm_client_contract_test.dart`)
- [x] [U17] Test: 429 retried then succeeds (`llm_client_contract_test.dart`)
- [x] [U18] Test: stream emits deltas reassembled into final message (`llm_client_contract_test.dart`)
- [x] Impl (PR #71): streaming transport + contract suite
- [x] [A3] Gate: Story 3 acceptance test (`stream emits the canonical text deltas`) green before story complete
