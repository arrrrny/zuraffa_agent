# Tasks: Fallback Chain Runtime

**Input**: Design documents from `/specs/008-fallback-chain-runtime/`

**Prerequisites**: plan.md (required), spec.md (required for user stories)

**Tests**: MANDATORY (TDD extension active; every behavioral task is driven test-first with recorded red evidence — per spec 007's verification remediation T046, one behavior per red).

**Organization**: Entities first (pre-existing red tests are the contracts), then the breaker state machine, then the chain runtime, then acceptance closure.

## Phase 1: Entities (US2 + US3 data contracts)

- [X] T001 [U1][U2][U3][U4] Test (pre-existing, loading-red at baseline): `client_health_test.dart` — construction/defaults, copyWith, JSON round-trip, breaker-state shapes
- [X] T002 [U1][U2][U3][U4] Implement `lib/src/domain/entities/client_health/client_health.dart`
- [X] T003 [U5] Test (pre-existing, loading-red): `fallback_chain_test.dart` — merged FallbackChain fields, copyWith, equality, JSON round-trip incl. breakerStates
- [X] T004 [U5] Implement the merged `FallbackChain` value object (spec-053 fields + chain config; both lineages green)

**Checkpoint**: entity contracts green; spec-053 provider tests still green.

---

## Phase 2: Circuit breaker (US2 runtime)

- [X] T005 [U6] Test: breaker opens after maxConsecutiveFailures consecutive failures
- [X] T006 [U6] Implement open transition in `lib/src/llm/circuit_breaker.dart`
- [X] T007 [U7] Test: open breaker transitions to half-open when the cooldown elapses (injected clock)
- [X] T008 [U7] Implement cooldown transition
- [X] T009 [U8] Test: half-open success closes; half-open failure re-opens
- [X] T010 [U8] Implement probe outcomes
- [X] T011 [U9] Test: attempt gating (open blocks, cooldown-elapsed allows one probe) and ClientHealth projection
- [X] T012 [U9] Implement gating + `health()` projection

---

## Phase 3: Chain runtime — generate() (US1)

- [X] T013 [U10] Test: provider A failing with a connection error → B serves the call transparently
- [X] T014 [U10] Implement `FallbackChainClient.generate()` failover loop (`lib/src/llm/fallback_chain_client.dart` + `test/llm/fake_llm_client.dart`)
- [X] T015 [U11] Test: advances on 5xx and on a 429 that exhausted retries; does NOT advance on other 4xx (fails fast)
- [X] T016 [U11] Implement the error classifier
- [X] T017 [U12] Test: context-overflow errors advance
- [X] T018 [U12] Implement context-overflow detection
- [X] T019 [U13] Test: all providers failing throws a chain-exhausted error carrying per-provider errors
- [X] T020 [U13] Implement exhaustion error
- [X] T021 [U14] Test: an open breaker skips its provider entirely (no call recorded)
- [X] T022 [U14] Implement breaker gating in the loop
- [X] T023 [U15] Test: after cooldown, a half-open probe routes real traffic back to A on success
- [X] T024 [U15] Implement probe routing

---

## Phase 4: Chain runtime — stream() (US1 scenario 3)

- [X] T025 [U16] Test: mid-stream failure on A restarts the generation on B — consumer sees A's partial chunks then B's complete stream; never silently truncates
- [X] T026 [U16] Implement stream failover with the restart policy
- [X] T027 [U17] Test: policy `skip` propagates mid-stream errors (configurable)
- [X] T028 [U17] Implement the policy switch

---

## Phase 5: Health snapshot (US3)

- [X] T029 [U18] Test: `healthSnapshot()` returns Map<provider, ClientHealth> matching live breaker states immediately after each transition
- [X] T030 [U18] Implement the snapshot API

---

## Phase 6: Closing gates

- [X] T031 [A1][A2][A3][A4][A5][A6][A7] Outer-loop acceptance check: AC-1..AC-7 green through FallbackChainClient's public API (with the entity tests standing for the entity-level criteria)
- [X] T032 `dart analyze` pristine for all files added/changed by this feature (SC-004)
- [X] T033 Full-suite delta check: zero NEW failures; the two baseline entity loading failures disappear (−2 → 406+ passing); commit spec-kit artifacts

---

## Phase 7: TDD remediation (from tdd/verification.md — verdict: PASS_WITH_GAPS)

- [ ] T034 [MED] Run single-test commands without piping through `tail` (or check `${PIPESTATUS[0]}`) so a red can never be committed silently — two such commits (657ff3d, 7793f36) were caught only by the next full-suite run. Proven by: no commit lands while its cycle test is red.
