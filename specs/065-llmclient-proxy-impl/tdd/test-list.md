---
feature: 065-llmclient-proxy-impl
loop: outside-in
profile: .specify/memory/tdd-profile.md
spec_criteria: 3 # three user-story acceptance behaviors (A1–A3)
planned_at: 40dfa21 # master at merge of PRs 69–72
updated_at: 40dfa21
suite_baseline: green # 909 tests passed, dart analyze clean
---

# Test List: Full LlmClient with Local Proxy Support (spec 065)

> Derived from `spec.md` (FR-001…FR-010, 3 user stories, edge cases) on branch
> `tdd/065-llmclient-proxy-impl`. **Note:** `plan.md` is absent for this feature,
> so component placement below is inferred from `spec.md` §Key Entities and the
> existing source, not from a plan document. The feature is already implemented
> (PR #71 merged) with five existing test files; behaviors already covered by a
> passing test are recorded `DONE` with that test named. The two unit gaps
> originally left open (`U4`, `U11`) have since been driven to `DONE`; no
> behavior on this list is open.

## Outer loop: acceptance behaviors

One per user story in `spec.md`. Each stays red until the feature works end to end
through its real entry point.

| id  | behavior                                                                                  | traces | kind     | state   | test                                                                                  |
| --- | ----------------------------------------------------------------------------------------- | ------ | ------- | ------- | ------------------------------------------------------------------------------------- |
| A1  | A live chat-completion call through the local proxy returns a non-empty assistant message with usage; proxy unreachable surfaces a typed error and the test skips | US1    | example | DONE    | `test/integration/llm_client_proxy_test.dart::performs a real completion through the proxy` |
| A2  | `LlmClientProvider.current()` resolves the active `LlmClient` (provider, model, capability flags) from provider config and no longer throws `UnimplementedError` | US2, FR-006 | example | DONE | `test/data/providers/llm_client/llm_client_provider_test.dart::LlmClientProvider.current returns the active LlmClient (no longer stubbed)` |
| A3  | When the resolved client advertises `supportsStreaming`, streamed (SSE) completions arrive as deltas and reassemble into the non-streaming equivalent | US3, FR-010 | example | DONE | `test/llm/llm_client_contract_test.dart::stream emits the canonical text deltas, assembled tool call, and completing usage chunk` |

## Inner loop: unit behaviors

Grouped by the component from `spec.md` §Key Entities that owns them.

### `lib/src/data/providers/llm_client/llm_http_transport.dart` (LlmTransport I/O boundary)

| id  | behavior                                                                      | traces     | kind     | state    | test                                                                              |
| --- | ----------------------------------------------------------------------------- | ---------- | -------- | -------- | --------------------------------------------------------------------------------- |
| U1  | Builds an OpenAI-compatible request body with messages and model               | FR-004     | example  | DONE     | `test/data/providers/llm_client/llm_http_transport_test.dart::builds an OpenAI-compatible body with messages and model` |
| U2  | Honors the `stream` flag in the request body                                  | FR-010     | example  | DONE     | `test/data/providers/llm_client/llm_http_transport_test.dart::honors the stream flag` |
| U3  | When `proxyUrl` is set, routes all traffic through it via `HttpClient.findProxy` | FR-002     | example  | DONE     | `test/integration/llm_client_proxy_test.dart::performs a real completion through the proxy` |
| U4  | When `proxyUrl` is empty/null, connects directly (no `findProxy` assigned)     | FR-002     | example  | DONE    | `test/data/providers/llm_client/llm_http_transport_test.dart::connects directly (no findProxy) when proxyUrl is null or empty` |
| U5  | Parses assistant `content`, `reasoning`/`thinking`, `finishReason`, and `usage` | FR-005     | example  | DONE     | `test/data/providers/llm_client/llm_http_transport_test.dart::parses content, reasoning, finish reason and usage` |
| U6  | Reassembles `reasoning` from `reasoning_details` when `reasoning` is absent    | FR-005     | example  | DONE     | `test/data/providers/llm_client/llm_http_transport_test.dart::reassembles reasoning from reasoning_details when reasoning is absent` |
| U7  | Raises a typed error (no partial parse) when `choices` is missing              | FR-005, edge | example | DONE     | `test/data/providers/llm_client/llm_http_transport_test.dart::throws when choices are missing` |
| U8  | Raises a typed error when `content` is empty                                   | FR-005, edge | example | DONE     | `test/data/providers/llm_client/llm_http_transport_test.dart::throws when content is empty` |

### `lib/src/data/providers/llm_client/llm_client_provider.dart` (config resolution)

| id  | behavior                                                          | traces       | kind     | state    | test                                                                                  |
| --- | ----------------------------------------------------------------- | ------------ | -------- | -------- | ------------------------------------------------------------------------------------- |
| U9  | `current()` returns the active `LlmClient` from config (not stubbed) | FR-006       | example  | DONE     | `test/data/providers/llm_client/llm_client_provider_test.dart::LlmClientProvider.current returns the active LlmClient (no longer stubbed)` |
| U10 | `count()` returns the number of usable configured clients          | FR-006       | example  | DONE     | `test/data/providers/llm_client/llm_client_provider_test.dart::LlmClientProvider.count returns the number of usable clients` |
| U11 | Forwards `ProviderConfig.timeoutMs` to the transport's completion call | FR-003 (impl) | example  | DONE    | `test/data/providers/llm_client/llm_client_provider_test.dart::forwards ProviderConfig.timeoutMs to the transport completion timeout` |

### `lib/src/domain/entities/llm_client/*` (ChatMessage / ChatCompletion / LlmClient value objects)

| id  | behavior                                                                     | traces     | kind     | state   | test                                                                                |
| --- | ---------------------------------------------------------------------------- | ---------- | -------- | ------- | ----------------------------------------------------------------------------------- |
| U12 | `LlmClient` equality is value-based across all fields                          | FR-006     | example  | DONE    | `test/data/providers/llm_client/llm_client_provider_test.dart::LlmClient equality is value-based across all fields` |
| U13 | `ChatMessage`/`ChatCompletion`/`LlmUsage`/`LlmResponse`/`LlmResponseChunk` are value types with spec-exact fields | FR-005     | example  | DONE    | `test/llm/llm_client_test.dart::LlmClient value objects (U1)` |
| U14 | `LlmHttpException` carries provider, status, body, and a readable message     | FR-005, edge | example  | DONE    | `test/llm/llm_client_test.dart::LlmHttpException (U2) carries provider, statusCode, body, and a readable message` |

### `test/llm/llm_client_contract_test.dart` (LlmClient contract suite)

| id  | behavior                                                                   | traces       | kind      | state   | test                                                                                  |
| --- | -------------------------------------------------------------------------- | ------------ | --------- | ------- | ------------------------------------------------------------------------------------- |
| U15 | `generate()` returns the canonical content, usage, and finish reason        | FR-001       | contract  | DONE    | `test/llm/llm_client_contract_test.dart::generate returns the canonical content, usage, and finish reason` |
| U16 | A non-2xx response raises `LlmHttpException` with status and body (no partial parse) | edge       | contract  | DONE    | `test/llm/llm_client_contract_test.dart::a non-2xx response raises LlmHttpException with status and body` |
| U17 | A 429 is retried and then succeeds                                         | edge         | contract  | DONE    | `test/llm/llm_client_contract_test.dart::a 429 is retried and then succeeds` |
| U18 | `stream()` emits deltas reassembled into the final message                 | FR-010       | contract  | DONE    | `test/llm/llm_client_contract_test.dart::stream emits the canonical text deltas, assembled tool call, and completing usage chunk` |

## Invariants and edge cases still to place

- **Secrets hygiene (edge case, FR implied):** the request/diagnostic path must never
  log the API key. No current test asserts this because there is no log sink to
  capture; it needs either a test double around the logger or stdout/stderr
  capture. Left here until a sink exists — not yet a numbered `U`.
- **Large completion / thinking tokens parsed without truncation:** covered
  indirectly by `U6` (reasoning_details reassembly); no dedicated oversized-payload
  test, but the parse path is allocation-based and not length-gated.

## Out of scope

- Full engine-loop orchestration (specs 002 / 045): separate effort; this feature
  delivers the working client, its transport, and the integration test only.
- Model/provider specifics (kilo.ai, `tencent/hy3:free`): environment config, not
  feature behavior.
- `dart:io` purity (FR-007): enforced by the CI engine-purity gate and the
  allowlist additions in `pipeline.yml`, not by a unit test.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md` at planning time:

- Single test: `dart test {file} -n "{name}"`
- Full suite: `dart test`
- Coverage: `dart test --coverage=.dart_coverage {files}` (format with
  `dart run coverage:format_coverage --packages=.dart_tool/package_config.json --report-on=lib --in=.dart_coverage -l`)
- Mutation / property-based: **not available** in this repo (no `mutation_test` /
  `glados` in the lockfile) — the audit uses deliberate mutants instead.
