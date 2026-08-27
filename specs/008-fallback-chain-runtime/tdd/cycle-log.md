# Cycle Log: Fallback Chain Runtime

Append only. Newest last. Every entry's `red` block is the evidence that the test
existed and failed before the implementation.

## Baseline

- suite: `dart test` -> 413 passed, 8 failed (all loading failures: the 6
  unrelated pre-existing files plus client_health_test and fallback_chain_test,
  which this feature implements — their red is the feature's starting evidence).
- commit: `16ad31f` (spec 007 head)
- recorded: cycle 0, before any 008 change.
- green criterion per cycle: the cycle's test passes AND the full-suite failure
  delta vs this baseline is zero new (the two entity loading failures are
  expected to disappear during Phase 1: baseline becomes 413+2 passed / 6
  failed).

## Cycle 1: U1-U4 ClientHealth entity — pre-existing red tests flip green

- test: `test/domain/entities/client_health_test.dart` (9 tests, PRE-EXISTING
  in master history before this branch — the strongest test-first evidence:
  the tests predate the implementation by 9+ commits)
- red: `dart test test/domain/entities/client_health_test.dart`
  -> `Failed to load ... uri_does_not_exist: package:zuraffa_agent/src/domain/entities/client_health/client_health.dart`
- green: `ClientHealth` value object (auto id, state/failure/cooldown/
  lastFailureAt/isHealthy, copyWith preserving id, toJson/fromJson round-trip
  incl. minimal JSON). Suite -> 422 passed, 7 failed (entity loading failure
  gone)
- refactor: none needed
- commit: `0a68279`

## Cycle 2: U5 merged FallbackChain entity — pre-existing red tests + green characterization

- test: `test/domain/entities/fallback_chain_test.dart` (7 tests,
  PRE-EXISTING) + characterization: `test/data/providers/fallback_chain/...`
  (5 tests, green at baseline, must stay green)
- red: `dart test test/domain/entities/fallback_chain_test.dart`
  -> `Error: No named parameter with the name 'providerOrder'` /
  `Member not found: 'FallbackChain.fromJson'` (compile red on the merged
  contract)
- green: merged value object — spec-053 field set (id/providerIds/
  currentProviderIndex/advances/lastErrorClass) + chain config
  (providerOrder/maxConsecutiveFailures/cooldownMs/policyMode/breakerStates/
  lastProviderIndex), auto id, copyWith, deep value equality, full JSON
  round-trip. Both lineages green. Suite -> 429 passed, 6 failed (both entity
  loading failures now gone; only the 6 unrelated baseline failures remain)
- refactor: none needed
- commit: `0d26a30`

## Cycle 3: U6 breaker opens after maxConsecutiveFailures

- test: `test/llm/circuit_breaker_test.dart::U6` (new)
- red: -> `UnimplementedError`
- green: closed/open transitions with failure counting. Suite -> 430 passed, 6 failed
- commit: `a849d3f`

## Cycle 4: U7 open -> half-open after cooldown

- test: `test/llm/circuit_breaker_test.dart::U7` (new)
- red: -> `Expected: CircuitState:<CircuitState.halfOpen> Actual: CircuitState:<CircuitState.open>`
- green: lazy cooldown transition in the `state` getter (59999ms keeps open;
  60000ms transitions). Suite -> 431 passed, 6 failed
- commit: `9fe89a9`

## Cycle 5: U8 half-open probe outcomes

- test: `test/llm/circuit_breaker_test.dart::U8` (new)
- red: -> `Expected: <1> Actual: <4>` (probe failure must reset the count)
- green: half-open probe failure re-opens with a fresh count of 1; probe
  success closes and resets. Suite -> 432 passed, 6 failed
- commit: `60efe42`

## Cycle 6: U9 attempt gating + health projection

- test: `test/llm/circuit_breaker_test.dart::U9` (new)
- red: -> `Error: The method 'attemptAllowed' isn't defined` then, after the
  declaration existed, `Expected: false Actual: true` on `health.isHealthy`
  (half-open must project unhealthy per the lineage entity contract)
- green: `attemptAllowed()` gating + `health()` projecting ClientHealth with
  isHealthy == (state == closed)
- notes: the first green commit `657ff3d` still contained the failing isHealthy
  assertion (pipeline exit code masked the red); fixed in `115f5bc`. Honest
  wart recorded.
- commits: `657ff3d` (red committed by mistake), `115f5bc` (green)

## Cycle 7: U10 chain generate() advances on connection error

- test: `test/llm/fallback_chain_client_test.dart::U10` (new; with the
  FakeLlmClient helper)
- red: -> `UnimplementedError`
- green: minimal failover loop — advance on LlmNetworkException, rethrow
  otherwise, breakers record outcomes (no gating yet: U14). Suite -> 434
  passed, 6 failed
- commit: `379d3b5`

## Cycle 8: U11 advance on 5xx/429, fail fast on other 4xx

- test: `test/llm/fallback_chain_client_test.dart::U11` (new)
- red: -> 5xx case failed (rethrown instead of advancing)
- green: `_shouldAdvance` classifier (network / >=500 / 429). Suite -> 435
  passed, 6 failed
- commit: `3a85062`

## Cycle 9: U12 advance on context overflow

- test: `test/llm/fallback_chain_client_test.dart::U12` (new)
- red: -> context-overflow 400 rethrown (B never served); plus one test-side
  paren fix before the red was valid
- green: body-pattern context-overflow detection (400/413 + regex). Suite ->
  436 passed, 6 failed
- commit: `747b823`

## Cycle 10: U13 chain-exhausted error

- test: `test/llm/fallback_chain_client_test.dart::U13` (new)
- red: -> `THREW: LlmHttpException: b returned HTTP 503` (last error rethrown,
  not the typed exhaustion error)
- green: `LlmFallbackExhaustedException` carrying errorsByProvider. Suite ->
  437 passed, 6 failed
- commit: `6b1efc4`

## Cycle 11: U14 open breaker skips its provider

- test: `test/llm/fallback_chain_client_test.dart::U14` (new)
- red: -> `Expected: 'from-b-again' Actual: 'a-recovered-early'` (A was called
  despite the open breaker)
- green: `attemptAllowed()` gate in the generate loop. Suite -> 438 passed,
  6 failed
- commit: `85a6a52`

## Cycle 12: U15 half-open probe routes traffic back — first-run pass, SURVIVING mutant, test rewritten, mutant killed

- test: `test/llm/fallback_chain_client_test.dart::U15` (new)
- red: none — passed on first run (gate + lazy half-open compose naturally)
- deliberate-mutant check: removing `breaker.recordSuccess()` from the chain
  SURVIVED the first test version (closed vs stuck-half-open were not
  distinguishable) — per the playbook the test was worthless and was rewritten:
  maxConsecutiveFailures=3 with post-probe failures pinning that the probe
  CLOSED the breaker. The rewritten test kills the mutant; re-run green.
- green: (implementation unchanged — the test was the fix)
- commits: `a044761` (weak test), strengthened test committed next

## Cycle 13: U16 mid-stream restart policy

- test: `test/llm/fallback_chain_client_test.dart::U16` (new)
- red: -> `UnimplementedError`
- green: stream() failover loop — partial chunks preserved, next provider
  completes the stream, breaker outcomes recorded. Suite -> 440 passed, 6 failed
- commit: `d9928c1`

## Cycle 14: U17 mid-stream skip policy

- test: `test/llm/fallback_chain_client_test.dart::U17` (new)
- red: -> `Expected: throws <LlmNetworkException> Actual: <Future>` (restart
  policy swallowed the error)
- green: `policyMode == 'skip'` propagates mid-stream errors after the partial
  chunks. Suite -> 441 passed, 6 failed
- commit: `6c49f5e`

## Cycle 15: U18 healthSnapshot

- test: `test/llm/fallback_chain_client_test.dart::U18` (new)
- red: -> `UnimplementedError`
- green: live `Map<String, ClientHealth>` over the breakers; test asserts
  real-time transitions across three generate calls. One test-side fix (B
  needed a third outcome) and one lint fix before green.
- commits: `7793f36` (red committed by masked exit code), `40b749a` (green)

## Audit-phase mutant sample (verification)

- chain gate removed -> U14 failed; skip/restart inverted -> U17 failed;
  snapshot hardcoded closed -> U18 failed. 3/3 caught, restored, suites green.
