# Cycle Log: LLM Provider Clients

Append only. Newest last. Every entry's `red` block is the evidence that the test
existed and failed before the implementation.

## Baseline

- suite: `dart test` -> 379 passed, 8 failed (all loading failures of tests referencing
  not-yet-implemented lib files from other features: in_memory_artifact_store,
  agent_spec, client_health, fallback_chain, sub_agent_type, golden_mission, suite,
  tool_dispatcher_impl). No test file for this feature exists yet.
- commit: `3adcd04`
- recorded: cycle 0, before any change (only markdown spec artifacts added since).
- deviation note: suite baseline is RED from pre-existing failures unrelated to this
  feature (documented in the TDD stack profile). Green criterion for every cycle
  below: the cycle's test passes AND the full suite shows zero NEW failures vs this
  baseline (client_health + fallback_chain entity loading failures are expected to
  persist unchanged through spec 007 and flip green in spec 008).

## Cycle 1: U1 value objects are value types

- test: `test/llm/llm_client_test.dart::LlmClient value objects (U1) LlmUsage, LlmToolCall, LlmResponse, LlmResponseChunk are value types with spec-exact fields` (new)
- red: `dart test test/llm/llm_client_test.dart --name "value types with spec-exact fields"`
  -> `Expected: <Instance of 'LlmUsage'> Actual: <Instance of 'LlmUsage'>` (identity equality; test line 17)
- green: value semantics (==/hashCode/copyWith) on the four value objects in
  `lib/src/llm/llm_client.dart`. Suite -> 380 passed, 8 failed (baseline unchanged)
- refactor: none needed
- commit: `2f98853`

## Cycle 2: U2 typed LlmHttpException

- test: `test/llm/llm_client_test.dart::LlmHttpException (U2) carries provider, statusCode, body, and a readable message` (new)
- red: `dart test test/llm/llm_client_test.dart --name "carries provider, statusCode, body"`
  -> `Expected: contains '503' Actual: 'LlmHttpException'`
- green: informative `toString()` on LlmHttpException. Suite -> 381 passed, 8 failed
- refactor: none needed
- commit: `a999071`

## Cycle 3: U3 transport seam round-trips via the fake

- test: `test/llm/llm_transport_test.dart::LlmTransport seam (U3) round-trips a request to a status/headers/body response and a line stream via the fake` (new)
- red: `dart test test/llm/llm_transport_test.dart --name "round-trips a request"`
  -> `UnimplementedError` (fake replay stubbed)
- green: seam data classes (`llm_transport.dart`) + full fixture-replaying
  `FakeLlmTransport` with request recording. Suite -> 382 passed, 8 failed
- refactor: none needed
- commit: `566d9a3`

## Cycle 4: U4 retry on 429 with one exponential backoff

- test: `test/llm/retry_test.dart::U4: a 429 then success is retried exactly once with one backoff delay` (new)
- red: `dart test test/llm/retry_test.dart --name "U4"` -> `UnimplementedError`
- green: `lib/src/llm/retry.dart` loop (retryable = 429/5xx/connection; delay =
  base << (attempt-1) + injected jitter; no cap yet). Suite -> 383 passed, 8 failed
- refactor: none needed
- commit: `a993347`

## Cycle 5: U5 retry on 5xx — passed on first run, mutant-verified

- test: `test/llm/retry_test.dart::U5: a 5xx then success is retried and succeeds` (new)
- red: none — test passed on first run (behavior already covered by the U4 loop's retryable set)
- deliberate-mutant check: `_isRetryableStatus`: `status >= 500` mutated to
  `status > 500` -> U5 failed (`Some tests failed`), restored via
  `git checkout lib/src/llm/retry.dart`, re-run green. Test pins the behavior.
- green: suite unchanged by test addition
- refactor: none needed
- commit: `de9f391` (test commit; mutants restored before it)

## Cycle 6: U6 exhaustion throws after maxAttempts — passed on first run, mutant-verified

- test: `test/llm/retry_test.dart::U6: exhausted retries throw the last HTTP error after maxAttempts attempts` (new)
- red: none — passed on first run
- deliberate-mutant check: exhaustion guard `attempt >= config.maxAttempts`
  mutated to `attempt > config.maxAttempts` -> U6 failed
  (`Expected: an object with length of <3>` — requests leaked past budget),
  restored, re-run green.
- refactor: none needed
- commit: `de9f391`

## Cycle 7: U7 non-retryable 4xx fails immediately — passed on first run, mutant-verified

- test: `test/llm/retry_test.dart::U7: a non-retryable 4xx is thrown immediately with zero retries` (new)
- red: none — passed on first run
- deliberate-mutant check: `_isRetryableStatus` mutated to return `true` for all
  statuses -> U7 failed (`Expected: throws ... statusCode: <401>`), restored,
  re-run green. Suite after restores -> 386 passed, 8 failed.
- refactor: none needed
- commit: `de9f391`

## Cycle 8: U8 exponential growth, cap, deterministic jitter

- test: `test/llm/retry_test.dart::U8: backoff delays grow exponentially, are capped, and jitter is deterministic` (new)
- red: `dart test test/llm/retry_test.dart --name "U8"`
  -> `Expected: [100, 200, 250, 250] Actual: [100, 200, 400, 800]` (cap missing)
- green: `(core + jitter).clamp(0, maxDelayMs)` in `_delayFor`. Suite -> 387
  passed, 8 failed
- refactor: none needed
- commit: `cf621e5`

## Cycle 9: U9 Retry-After overrides computed backoff

- test: `test/llm/retry_test.dart::U9: a Retry-After header overrides the computed backoff delay` (new)
- red: `dart test test/llm/retry_test.dart --name "U9"`
  -> `Expected: [7000] Actual: [100]`
- green: `_retryAfterMs` header parse (seconds, clamped 0..3600 s, NOT clamped
  by maxDelayMs — server directive). Suite -> 388 passed, 8 failed
- notes: first green commit `db9412f` carried a compile error (`int.clamp`
  returns `num`), caught by the full-suite run (loading failure); fixed in
  `fba4476`. Recorded here rather than amended.
- refactor: none needed
- commits: `db9412f` (broken), `fba4476` (fix; the cycle's green commit)

## Cycle 10: U10 dart:io adapter maps the seam onto HttpClient

- test: `test/llm/io_llm_transport_test.dart::IoLlmTransport (U10) maps LlmHttpRequest onto HttpClient producing status, headers, body, and a line stream` (new)
- red: `dart test test/llm/io_llm_transport_test.dart --name "U10"`
  -> `UnimplementedError`
- green: `IoLlmTransport` over a loopback `HttpServer` (request headers/body
  verified server-side; SSE lines decoded through LineSplitter); registered in
  the CI purity allowlist with justification. Suite -> 389 passed, 8 failed
- refactor: none needed
- commit: `a990410`

## Cycle 11: U11 OpenAI generate() request/response mapping

- test: `test/llm/openai_compatible_client_test.dart::U11: generate() builds the chat/completions body (model, multimodal messages, tools) and parses content, finishReason, usage` (new)
- red: `dart test test/llm/openai_compatible_client_test.dart --name "U11"`
  -> `UnimplementedError`
- green: `OpenAiCompatibleClient.generate()` with AgentMessage -> wire mapping
  (system/user incl. image data-URL parts/assistant tool_calls replay/tool
  role) and response parsing (content, tool calls, usage incl.
  cached+reasoning tokens, finish reason)
- notes: two fix commits inside the green step — `04b2852` had a Map-vs-String
  compile error, `0897f14` a double-slash endpoint URL; both caught by
  analyze/suite and fixed before the cycle's green commit `e9658aa`.
  Suite -> 390 passed, 8 failed
- refactor: none needed
- commit: `e9658aa` (span start `04b2852`)

## Cycle 12: U12 OpenAI SSE streaming with usage + [DONE]

- test: `test/llm/openai_compatible_client_test.dart::U12: stream() parses SSE data lines to content deltas; the final chunk carries usage; [DONE] yields isComplete` (new)
- red: `dart test test/llm/openai_compatible_client_test.dart --name "U12"`
  -> `UnimplementedError`
- green: SSE line parser (skips blanks/`:`-comments), content deltas pass
  through, usage chunk + `[DONE]` finalize with isComplete; added
  `openStreamWithRetry` to retry.dart. Suite -> 391 passed, 8 failed
- refactor: extracted `_OpenAiToolBuffer` accumulation shared by the
  finish_reason and finalize paths
- commit: `bab7144`

## Cycle 13: U13 interleaved tool fragments + malformed arguments — fixture repair then mutant-verified

- test: `test/llm/openai_compatible_client_test.dart::U13: tool-call fragments assemble by index across chunks; malformed arguments default to an empty map` (new)
- red: first red was a TEST bug, not the behavior: the python-authored fixture
  lost JSON escaping, making two SSE lines invalid JSON (silently skipped) ->
  `Expected: an object with length of <2> Actual: [... call_b ...]`. Fixture
  repaired to the intended wire data; behavior then passed on first run
  (index-keyed buffering already implemented in the U12 green).
- deliberate-mutant check: fragment keying mutated to `final index = 0;` ->
  U13 failed (`name: get_weatherget_time` merged buffers), restored via git,
  re-run green.
- green: suite -> 391 passed, 8 failed (before U14's test lands)
- refactor: none needed
- commit: `bbca527`

## Cycle 14: U14 non-2xx raises typed error through the client — passed first run, mutant-verified

- test: `test/llm/openai_compatible_client_test.dart::U14: a non-2xx response raises LlmHttpException with statusCode and body` (new)
- red: none — passed on first run (sendWithRetry already throws; client surfaces)
- deliberate-mutant check: generate() mutated to catch LlmHttpException and
  return an empty LlmResponse -> U14 failed (`Expected: throws ... statusCode:
  <500>`), restored, re-run green. Suite -> 393 passed, 8 failed.
- refactor: none needed
- commit: `bbca527`

## Cycle 15: U15 Anthropic generate() with thinking + tool_use

- test: `test/llm/anthropic_client_test.dart::U15: generate() builds the Messages body (system, messages, tools) and parses content blocks incl. thinking` (new)
- red: `dart test test/llm/anthropic_client_test.dart --name "U15"`
  -> `UnimplementedError`
- green: full `AnthropicClient` (Messages body: system param, base64
  image/document blocks, tool_use replay, tool_result user blocks;
  response parse: text/thinking/tool_use; usage incl. cache_read_input_tokens;
  stop_reason normalization end_turn->stop, tool_use->tool_calls, max_tokens->length).
  Suite -> 394 passed, 8 failed
- refactor: follow-up lint commits for analyze pristinity
  (`?'x-api-key'` -> `'x-api-key': ?apiKey` null-aware element)
- commits: `50537c4`, `8476211`

## Cycle 16: U16 Anthropic stream events — passed first run, mutant-verified

- test: `test/llm/anthropic_client_test.dart::U16: stream() parses message_start usage, thinking/text deltas, and message_delta stop reason + output usage` (new)
- red: none — passed on first run (stream parser landed with the U15 green)
- deliberate-mutant check: `case 'thinking_delta':` mutated to a dead label ->
  U16 failed (no thinking chunk), restored, re-run green
- refactor: none needed
- commit: (test commit follows in this batch)

## Cycle 17: U17 tool_use fragment assembly — fixture repair, then pass; mutant-verified

- test: `test/llm/anthropic_client_test.dart::U17: tool_use blocks assemble from input_json_delta partial_json fragments` (new)
- red: first red was again a fixture-escaping bug (three SSE lines rendered
  invalid JSON; two fixed, one missed) -> arguments assembled to `{}`. All
  three repaired; behavior passed (assembly already implemented).
- deliberate-mutant check: `buffer.arguments += ...` mutated to append nothing
  -> U17 failed, restored, re-run green
- refactor: none needed

## Cycle 18: U18 Anthropic non-2xx typed error — passed first run, mutant-verified

- test: `test/llm/anthropic_client_test.dart::U18: a non-2xx response raises a typed error` (new)
- red: none — passed on first run
- deliberate-mutant check: provider label mutated to 'wrong' -> U18 failed,
  restored, re-run green. Suite -> 397 passed, 8 failed.
- refactor: none needed

## Cycle 19: U19 Gemini generate() with function calling + usageMetadata

- test: `test/llm/gemini_client_test.dart::U19` (new)
- red: `dart test test/llm/gemini_client_test.dart --name "U19"` -> `UnimplementedError`
- green: `GeminiClient` (contents/parts mapping incl. inlineData + functionCall/
  functionResponse, systemInstruction, functionDeclarations, generationConfig;
  parse: text + functionCall parts, usageMetadata prompt/candidates/cached/
  thoughts, finishReason normalization STOP->stop, MAX_TOKENS->length,
  SAFETY/RECITATION->content_filter). Suite -> 398 passed, 8 failed
- notes: id synthesis reads functionCall['id'] falling back to call_<n> (the
  first cut wrongly used name); fixed within the cycle before green commit
  `e6d6bf0`
- refactor: none needed
- commit: `e6d6bf0`

## Cycles 20-22: U20 Gemini stream, U21 malformed function call, U22 errors — passed first run, mutant-verified

- tests: `test/llm/gemini_client_test.dart::U20/U21/U22` (new)
- red: none — all three passed on first run (stream parser landed with U19)
- deliberate-mutant checks (each restored via git, re-run green):
  - U20: `functionCall` part extraction mutated to null -> suite failed
  - U21: MALFORMED_FUNCTION_CALL normalization mutated to 'stop' -> failed
  - U22: provider label mutated to 'wrong' -> failed
- green: suite -> 401 passed, 8 failed
- refactor: none needed
- commit: `0c1b595`

## Cycles 23-26: A1/A4/A6/A8 shared contract suite over recorded fixtures

- tests: `test/llm/llm_client_contract_test.dart` (new, 12 tests) + 12 wire
  fixture files under `test/fixtures/llm/{openai,anthropic,gemini}/`
- red: genuine red on the first run: anthropic stream cached tokens
  `Expected: <8> Actual: <0>` (client did not parse cache_read_input_tokens
  from message_start) — a real behavioral gap found by the suite; and the
  error-scenario clients needed no-retry configuration (single scripted 500
  was retried into transport exhaustion)
- green: anthropic client parses cache_read_input_tokens on message_start;
  suite parameterizes retryConfig per scenario; all 12 contract tests pass
- deliberate-mutant checks (A-behaviors; each restored, suite re-run green):
  - A1 openai: content deltas dropped -> openai suite failed
  - A4 anthropic: message_delta usage dropped -> anthropic suite failed
  - A6 gemini: usageMetadata ignored -> gemini suite failed
  - A8: equivalence is structural — one shared suite function, identical
    client-level assertions, per-provider fixtures
- notes: a `git checkout` mutant-restore clobbered the then-uncommitted
  cachedTokens fix; the suite caught it on the next full run (+412 -9) and it
  was re-applied in `9117fa2`. Honest warts recorded.
- green: suite -> 413 passed, 8 failed (baseline delta zero)
- commits: `9b418a1`, `9117fa2`
