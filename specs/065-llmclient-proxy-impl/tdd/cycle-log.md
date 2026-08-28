# Cycle Log: Full LlmClient with Local Proxy Support (spec 065)

Append only. Newest last. Every entry's `red` block is the evidence that the test
existed and failed before the implementation.

## Baseline

- suite: `dart test` -> 909 passed, 0 failed (full suite, ~104s)
- analyze: `dart analyze` clean (0 issues)
- commit: `40dfa21`
- recorded: cycle 0, before any TDD change on branch `tdd/065-llmclient-proxy-impl`
- note: feature already implemented and merged (PR #71); this log captures the
  subsequent TDD-driven gap-closing cycles (U4, U11) and any refactors.

## Cycle 1 — U4 (direct connect when proxyUrl null/empty)

- behavior: `U4` — when `proxyUrl` is null or empty, `LlmHttpTransport.complete`
  must NOT install an `HttpClient.findProxy` resolver (connects directly).
- kind: test-after (implementation already merged via PR #71). Per speckit-tdd-run
  Hard Rule 2 this is recorded as test-after; the deliberate-mutant check below
  still proves the test is sensitive, so it is a meaningful (not vacuous) test.
- test: `test/data/providers/llm_client/llm_http_transport_test.dart` ::
  `connects directly (no findProxy) when proxyUrl is null or empty`
  (added a `MockHttpClient extends Mock implements HttpClient` that records
  `findProxy` assignment; `postUrl` throws a `SocketException`, `close` is a
  no-op, so no real network occurs).
- red: implementation pre-existed, so a direct red could not be observed. Applied
  a deliberate mutant to `llm_http_transport.dart` (guard flipped to
  `proxyUrl == null || proxyUrl.isNotEmpty` with a non-null fallback host) so the
  resolver is assigned even for a null proxy. Single-test run then failed for the
  right reason:
  ```
  dart test test/data/providers/llm_client/llm_http_transport_test.dart -n "no findProxy"
  Expected: false
    Actual: <true>
  findProxy must not be installed when proxyUrl is null
  ```
- green: reverted the mutant to the original guard
  (`proxyUrl != null && proxyUrl.isNotEmpty`); single test passes. Full suite:
  909 passed, 0 failed. `dart analyze` clean.
- refactor: none required (test mirrors the existing `llm_http_transport_test`
  style; the recorder is a minimal inert HttpClient double).
- notes: selection used `-n "no findProxy"` because parentheses in the test name
  break the `-n` regex (a `No tests ran.` exit-0 trap); a substring avoids it.
- commit: 0b96826

## Cycle 2 — U11 (timeout forwarded from ProviderConfig)

- behavior: `U11` — `LlmClientProvider.complete` forwards
  `ProviderConfig.timeoutMs` into the transport's `complete(timeout:)` arg.
- kind: test-after (implementation already merged via PR #71). Recorded as
  test-after per speckit-tdd-run Hard Rule 2; deliberate-mutant check below
  proves the test is sensitive, so it is not vacuous.
- test: `test/data/providers/llm_client/llm_client_provider_test.dart` ::
  `forwards ProviderConfig.timeoutMs to the transport completion timeout`
  (added `MockLlmHttpTransport extends Mock implements LlmHttpTransport`; the
  provider is constructed with `transport:` injected, a `List<ChatMessage>`
  fallback is registered for `any()`, and `verify` asserts the exact
  `timeout: Duration(milliseconds: 30000)` reached the transport).
- red: implementation pre-existed, so a direct red could not be observed. Applied
  a deliberate mutant to `llm_client_provider.dart` (the forwarded
  `timeout: Duration(milliseconds: config.timeoutMs)` was replaced with
  `timeout: null`). Single-test run then failed for the right reason:
  ```
  dart test test/data/providers/llm_client/llm_client_provider_test.dart -n "forwards ProviderConfig.timeoutMs"
  No matching calls. All calls: MockLlmHttpTransport.complete({... timeout: null})
  ```
- green: reverted the mutant to the original
  `timeout: Duration(milliseconds: config.timeoutMs)`; single test passes. Full
  suite: 909 passed, 0 failed. `dart analyze` clean.
- refactor: none required (test mirrors the existing provider-test style).
- notes: `registerFallbackValue(<ChatMessage>[...])` (no type args) is required
  for `any(named: 'messages')`; the `<List<ChatMessage>>` generic form does not
  compile against mocktail 1.0.5.
- commit: 22bf1aa


