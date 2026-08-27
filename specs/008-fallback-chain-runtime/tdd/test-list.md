# Test List: Fallback Chain Runtime

---
feature: 008-fallback-chain-runtime
loop: outside-in
profile: .specify/memory/tdd-profile.md
spec_criteria: 7 # acceptance criteria AC-1..AC-7 in spec.md
planned_at: 16ad31f
updated_at: 40b749a
suite_baseline: red # pre-existing loading failures remain from unrelated features; green criterion = feature tests pass AND failure delta vs the spec-007 baseline (8 loading failures) is zero new (expected: -2 as the entity tests flip green)
---

## Outer loop: acceptance behaviors

One per acceptance criterion, through the feature's real entry point — `FallbackChainClient`'s public `generate()`/`stream()`/`healthSnapshot()` API (and the domain entities for the entity-level criteria).

| id  | behavior                                                                                  | traces | kind    | state   | test |
| --- | ----------------------------------------------------------------------------------------- | ------ | ------- | ------- | ---- |
| A1  | Provider A failing → B serves the call; the mission observes only latency                  | AC-1   | example | DONE | `fallback_chain_client_test.dart::U10` |
| A2  | Open breaker + elapsed cooldown → half-open probe routes real traffic back on success      | AC-2   | example | DONE | `fallback_chain_client_test.dart::U15` |
| A3  | Mid-stream failure after partial chunks restarts on the next provider; never truncates     | AC-3   | example | DONE | `fallback_chain_client_test.dart::U16` |
| A4  | 3 consecutive failures open the breaker                                                    | AC-4   | example | DONE | `circuit_breaker_test.dart::U6` |
| A5  | CooldownMs elapse moves an open breaker to half-open                                       | AC-5   | example | DONE | `circuit_breaker_test.dart::U7` |
| A6  | A successful half-open probe closes the breaker                                            | AC-6   | example | DONE | `circuit_breaker_test.dart::U8` |
| A7  | The health snapshot matches internal breaker states at any time                            | AC-7   | example | DONE | `fallback_chain_client_test.dart::U18` + `client_health_test.dart` |

## Inner loop: unit behaviors

### `lib/src/domain/entities/client_health/client_health.dart` (pre-existing red tests)

| id  | behavior                                                                                  | traces        | kind    | state   | test |
| --- | ----------------------------------------------------------------------------------------- | ------------- | ------- | ------- | ---- |
| U1  | ClientHealth constructs with auto-generated non-empty id, state/failure/cooldown/healthy defaults | AC-7, FR-002 | example | DONE | `client_health_test.dart::construction and field access` |
| U2  | copyWith preserves id and applies overrides                                                | AC-7          | example | DONE | `client_health_test.dart::copyWith creates new instance` |
| U3  | toJson/fromJson round-trip preserves all fields; minimal JSON (no id) accepted             | AC-7          | example | DONE | `client_health_test.dart::fromJson round-trip` |
| U4  | closed/open/half-open states project their isHealthy/failure shape                         | AC-4, AC-5, AC-6 | example | DONE | `client_health_test.dart::Circuit Breaker States` |

### `lib/src/domain/entities/fallback_chain/fallback_chain.dart` (merged value object)

| id  | behavior                                                                                  | traces        | kind             | state   | test |
| --- | ----------------------------------------------------------------------------------------- | ------------- | ---------------- | ------- | ---- |
| U5  | FallbackChain carries providerOrder/maxConsecutiveFailures/cooldownMs/policyMode/breakerStates/lastProviderIndex with auto id, copyWith, equality, and JSON round-trip — while the spec-053 field set (id/providerIds/currentProviderIndex/advances/lastErrorClass) still constructs and compares by value | FR-001, FR-002 | example + characterization | DONE | `fallback_chain_test.dart` (7) + `fallback_chain_provider_test.dart` (5, characterization) |

### `lib/src/llm/circuit_breaker.dart`

| id  | behavior                                                                                  | traces        | kind    | state   | test |
| --- | ----------------------------------------------------------------------------------------- | ------------- | ------- | ------- | ---- |
| U6  | 3 consecutive failures (maxConsecutiveFailures=3) open the breaker                         | AC-4, FR-002  | example | DONE | `circuit_breaker_test.dart::U6` |
| U7  | An open breaker transitions to half-open when cooldownWindowMs elapses (injected clock)    | AC-5, FR-002  | example | DONE | `circuit_breaker_test.dart::U7` |
| U8  | A half-open probe success closes the breaker; a probe failure re-opens it                  | AC-6, FR-002  | example | DONE | `circuit_breaker_test.dart::U8` |
| U9  | Attempt gating: open blocks calls before cooldown, allows one probe after; health() projects ClientHealth | AC-2, AC-7, FR-005 | example | DONE | `circuit_breaker_test.dart::U9` |

### `lib/src/llm/fallback_chain_client.dart`

| id  | behavior                                                                                  | traces        | kind    | state   | test |
| --- | ----------------------------------------------------------------------------------------- | ------------- | ------- | ------- | ---- |
| U10 | generate() advances to provider B when A fails with a connection error and B serves        | AC-1, FR-001, FR-003 | example | DONE | `fallback_chain_client_test.dart::U10` |
| U11 | generate() advances on 5xx and on a 429 that exhausted the client's retries; fails fast on other 4xx | FR-003 | example | DONE | `fallback_chain_client_test.dart::U11` |
| U12 | generate() advances on context-overflow errors (400 + context-length body)                 | FR-003        | example | DONE | `fallback_chain_client_test.dart::U12` |
| U13 | All providers failing throws a chain-exhausted error carrying every provider's error       | FR-001        | example | DONE | `fallback_chain_client_test.dart::U13` |
| U14 | An open breaker skips its provider entirely (no call reaches it)                           | FR-002        | example | DONE | `fallback_chain_client_test.dart::U14` |
| U15 | After cooldown, a half-open probe routes real traffic back to A on success                 | AC-2          | example | DONE | `fallback_chain_client_test.dart::U15` (rewritten after surviving mutant) |
| U16 | stream() mid-stream failure on A restarts the generation on B; the consumer sees A's partial chunks then B's complete stream — never silent truncation | AC-3, FR-004 | example | DONE | `fallback_chain_client_test.dart::U16` |
| U17 | stream() mid-stream policy `skip` propagates the error to the consumer (configurable)      | FR-004        | example | DONE | `fallback_chain_client_test.dart::U17` |
| U18 | healthSnapshot() returns Map<provider, ClientHealth> matching live breaker states immediately after every transition | AC-7, FR-005 | example | DONE | `fallback_chain_client_test.dart::U18` |

## Invariants and edge cases still to place

- Breaker failure counts are per-provider and independent (one provider's outage never trips another's breaker) — placed inside U14/U18 assertions.
- A half-open breaker allows exactly one probe at a time — placed inside U9.
- Chain with a single provider behaves like the raw client (no failover possible; errors propagate as exhaustion) — placed inside U13's fixture variations.

## Out of scope

- Persistence of breaker state across engine restarts (feeds the session-store specs).
- Metrics/telemetry export of breaker transitions beyond the health snapshot.
- Engine-loop integration (spec 002's consumption of the fallback client).
- Load shedding / rate limiting across the chain (no requirement).

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md`:

- Single test: `dart test {file} --name "{name}" --reporter expanded`
- Full suite: `dart test`
- Coverage: `dart test --coverage=coverage`
- Mutation: none installed — deliberate mutants per rubric
