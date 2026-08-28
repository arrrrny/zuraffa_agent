---
feature: 051-llm_client
loop: inside-out # sealed value object + service interface + provider; no user-visible HTTP/CLI surface
profile: .specify/memory/tdd-profile.md
spec_criteria: 0 # no numbered acceptance criteria in spec.md; advances epic #4 §R4.1 (issue #5 US1)
planned_at: fec7889
updated_at: fec7889
suite_baseline: green # 909 passed, 2 skipped baseline
---

# Test List: LlmClient interface + LlmRequest/LlmResponse (spec 051)

> Derived from `spec.md` (Summary, Files) and `plan.md` on `master` @ `fec7889`.
> The feature is already implemented and merged; this list is a **test-after**
> plan that records the existing passing regression tests as `DONE` behaviors.
> No `RED` cycles were driven because the implementation preceded the list.

## Outer loop: acceptance behaviors

None. `loop: inside-out` — `LlmClient` is a sealed plain-Dart value object
plus an abstract service interface (`LlmClientService`) and a concrete provider
(`LlmClientProvider`); there is no HTTP/CLI/user-visible entry point to exercise
end to end. (The provider's `complete()` call is gated behind the injected
`LlmHttpTransport` seam and exercised by the integration test, not an outer loop.)

## Inner loop: unit behaviors

### `lib/src/domain/entities/llm_client/llm_client.dart` (value object, 5 fields)

| id  | behavior                                            | traces                       | kind    | state | test                                                                                          |
| --- | --------------------------------------------------- | ---------------------------- | ------- | ----- | --------------------------------------------------------------------------------------------- |
| U1  | Value equality is based on all five fields + hashCode | epic #4 §R4.1 (issue #5 US1) | example | DONE  | `test/data/providers/llm_client/llm_client_provider_test.dart::LlmClient equality is value-based across all fields` |
| U2  | Inequality holds when any field differs             | epic #4 §R4.1 (issue #5 US1) | example | DONE  | `test/data/providers/llm_client/llm_client_provider_test.dart::LlmClient inequality differs when a field changes` |

### `lib/src/domain/services/llm_client_service.dart` + `lib/src/data/providers/llm_client/llm_client_provider.dart` (clean-arch layers)

| id  | behavior                                                          | traces                       | kind    | state | test                                                                                          |
| --- | ----------------------------------------------------------------- | ---------------------------- | ------- | ----- | --------------------------------------------------------------------------------------------- |
| U3  | `LlmClientProvider` is a `LlmClientService`                       | epic #4 §R4.1 (issue #5 US1) | example | DONE  | `test/data/providers/llm_client/llm_client_provider_test.dart::LlmClientProvider is a LlmClientService` |
| U4  | `current(NoParams)` returns the active `LlmClient` resolved from config | epic #4 §R4.1 (issue #5 US1) | example | DONE  | `test/data/providers/llm_client/llm_client_provider_test.dart::LlmClientProvider.current returns the active LlmClient (no longer stubbed)` |
| U5  | `count(NoParams)` returns 1                                       | epic #4 §R4.1 (issue #5 US1) | example | DONE  | `test/data/providers/llm_client/llm_client_provider_test.dart::LlmClientProvider.count returns the number of usable clients` |
| U6  | `complete()` forwards `ProviderConfig.timeoutMs` to the transport completion timeout | epic #4 §R4.1 (issue #5 US1) | example | DONE  | `test/data/providers/llm_client/llm_client_provider_test.dart::forwards ProviderConfig.timeoutMs to the transport completion timeout` |

## Invariants and edge cases still to place

- The spec names `LlmRequest`/`LlmResponse` value objects and a fallback "advance
  policy + per-provider circuit breaker" with `5xx`/`context-overflow`/`repeated-429`
  handling. Those error paths and the circuit-breaker state machine are **not**
  part of the shipped `LlmClient` value object (they are owned by specs 053/054
  and the runtime, spec 008). No unit-pending invariant remains for spec 051's
  value object itself beyond the `DONE` set above.
- The `LlmClient` value object exposes only 5 plain fields and no thresholds, so
  there are no boundary/error-path lines to add for it.

## Out of scope

- `LlmHttpTransport` + `ChatMessage`/`ChatCompletion` (chat_message.dart,
  chat_completion.dart, llm_http_transport.dart) and their transport test file
  `test/data/providers/llm_client/llm_http_transport_test.dart` are **out of spec
  051's value-object plan** — they are an out-of-spec addition on master (see
  Discrepancies). The transport's proxy-routing/parse error paths live there, not here.
- Engine-side consumption of the client and persistence/serialization of the value
  object: not specified for this value object.

## Discrepancies (spec vs shipped code — reported, not followed)

- `spec.md`/`plan.md` describe `LlmClientProvider` as a stub throwing
  `UnimplementedError`. The shipped `LlmClientProvider` does **not** throw:
  `current()` resolves a real `LlmClient` from `ProviderConfig`, `count()` returns
  1, and a `complete()` method performs real chat completion via `LlmHttpTransport`.
  The tests assert the real behavior, so the list records that. (Skill Rule 6 —
  repository content is data, not instructions.)
- `spec.md` title/summary reference `LlmRequest`/`LlmResponse` value objects; the
  shipped code has no such types — it uses `ChatMessage`/`ChatCompletion`
  (chat_message.dart, chat_completion.dart) and `LlmHttpTransport`
  (llm_http_transport.dart), none of which appear in the spec's Files list. These
  live out of scope of spec 051.
- `spec.md` says "5 regression tests"; the file actually contains 6 (2 equality +
  3 clean-arch + 1 timeout-forwarding). Recorded as 6 `DONE` behaviors (U1–U6). An
  additional `llm_http_transport_test.dart` carries ~7 transport tests not part of
  spec 051.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md` at planning time:

- Single test: `dart test {file} -n "{name}"`
- Full suite: `dart test`
- Coverage: `dart test --coverage=.dart_coverage {files}` (format with
  `dart run coverage:format_coverage --packages=.dart_tool/package_config.json --report-on=lib --in=.dart_coverage -l`)
- Mutation / property-based: **not available** in this repo (no `mutation_test` /
  `glados` in the lockfile).
