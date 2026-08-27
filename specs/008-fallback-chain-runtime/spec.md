# Feature Specification: Fallback Chain Runtime

**Feature Branch**: `008-fallback-chain-runtime`

**Created**: 2026-08-27

**Status**: Approved *(refined by /speckit.specify — added acceptance-criterion ids AC-1..AC-9, measurable SCs, and assumptions resolving the entity merge with the spec-004 lineage tests and the mid-stream default policy)*

**Input**: Gap analysis vs dart_agent_core — entity stubs exist but no runtime logic for fallback, circuit breaker, or health tracking.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Fallback on provider failure (Priority: P1)

As the engine operator, I configure an ordered provider chain (e.g., self-host → frontier). On connection error, timeout, 5xx, context overflow, or repeated 429, the chain advances transparently.

**Why this priority**: BFCM-scale availability: one provider outage must not kill missions.

**Independent Test**: Outage fixtures trip the breaker on provider A, transparently serve via B, then A half-open probes and recovers.

**Acceptance Scenarios**:

1. **Given** provider A failing, **When** a call is made, **Then** B serves it; the mission observes only latency. **[AC-1]**
2. **Given** A in open state, **When** the cooldown elapses, **Then** a half-open probe routes real traffic back on success. **[AC-2]**
3. **Given** a mid-stream failure after partial chunks, **Then** the policy restarts on the next provider — never silently truncates. **[AC-3]**

### User Story 2 - Circuit breaker per provider (Priority: P1)

As the engine, each provider has an independent circuit breaker (open/half-open/closed) with configurable failure threshold and cooldown.

**Why this priority**: Prevents cascading failures and enables automatic recovery.

**Independent Test**: A provider that fails 3 times opens the circuit; after cooldown, a successful call closes it.

**Acceptance Scenarios**:

1. **Given** maxConsecutiveFailures=3, **When** 3 consecutive failures occur, **Then** the breaker opens. **[AC-4]**
2. **Given** an open breaker with cooldownMs=60000, **When** 60s elapse, **Then** the state transitions to half-open. **[AC-5]**
3. **Given** a half-open breaker, **When** a call succeeds, **Then** the state transitions to closed. **[AC-6]**

### User Story 3 - Health snapshot (Priority: P2)

As an operator/dashboard, I query `Map<provider, ClientHealth>` at any time to see breaker states, failure counts, and cooldown status.

**Why this priority**: Observability for the fallback chain at scale.

**Independent Test**: Breaker transitions are reflected in the snapshot immediately.

**Acceptance Scenarios**:

1. **Given** any chain state, **When** the snapshot is read, **Then** it matches the internal breaker states. **[AC-7]**

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A `FallbackChainClient` MUST wrap multiple `LlmClient` instances with automatic failover.
- **FR-002**: Each provider MUST have an independent circuit breaker (open/half-open/closed).
- **FR-003**: The chain MUST advance on connection error, timeout, 5xx, context overflow, or repeated 429.
- **FR-004**: Mid-stream failures MUST restart on the next provider (configurable policy).
- **FR-005**: A health snapshot API MUST expose chain state at any time.

### Key Entities

- **FallbackChainClient**: wraps LlmClient list with failover logic
- **CircuitBreaker**: state machine (closed → open → half-open → closed)
- **ClientHealth**: state, consecutiveFailures, cooldownWindowMs, lastFailureAt
- **FallbackChain** (evolved entity): chain configuration + advance policy + breaker states (providerOrder, maxConsecutiveFailures, cooldownMs, policyMode, breakerStates, lastProviderIndex) while remaining field-compatible with the spec-053 value object (id, providerIds, currentProviderIndex, advances, lastErrorClass)
- **ClientHealth** (new entity at `lib/src/domain/entities/client_health/`): id, state, consecutiveFailures, cooldownWindowMs, lastFailureAt, isHealthy + JSON round-trip — contract pinned by the pre-existing spec-004 lineage tests

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Outage fixtures trip and recover the breaker; mid-stream policy explicit (all AC-1..AC-6, AC-3 tests green through `FallbackChainClient`'s public API).
- **SC-002**: Health snapshot reflects breaker states in real-time (`dart test` green for the snapshot API over injected-clock transitions).
- **SC-003**: The pre-existing spec-004 lineage entity tests (`test/domain/entities/client_health_test.dart`, `test/domain/entities/fallback_chain_test.dart`) flip from loading-red to green without weakening the already-green spec-053 provider tests.
- **SC-004**: `dart analyze` pristine for all files added by this feature; full-suite failure delta vs. the spec-007 baseline is zero new failures (the two entity loading failures are expected to disappear, i.e. −2).

## Assumptions

- The chain runtime lives at `lib/src/llm/{circuit_breaker,fallback_chain_client}.dart` (spec 007's layer); the domain entities live at their spec-004 lineage paths.
- The pre-existing red tests `client_health_test.dart` and `fallback_chain_test.dart` (committed in master history BEFORE this feature) ARE the test-first contracts for the entities: their loading failures at baseline are the red evidence, and git history proves the tests predate the implementation.
- `FallbackChain` evolves as a merged value object carrying both the spec-053 fields (required by the green provider tests) and the chain-configuration fields (required by the red entity tests). The two field sets coexist; `providerOrder` is the runtime's ordered provider list (the legacy `providerIds` stays as the older alias).
- Mid-stream policy: `restart` (default for the runtime — spec scenario AC-3 says "never silently truncates") re-runs the whole generation on the next provider after partial chunks were already delivered; `skip` propagates the error. The `FallbackChain` entity's default `policyMode` remains `'skip'` because its lineage test pins that default; the runtime takes its policy explicitly.
- Error classification (FR-003): advance on `LlmNetworkException` (connection/timeout), `LlmHttpException` with status ≥ 500, 429 (a 429 that survived the client's internal retry budget — "repeated 429"), and context overflow (status 400 whose body indicates context-length exhaustion, e.g. `context_length`/`maximum context`/`too long`); do NOT advance on other 4xx (auth, bad request) — fail fast.
- Time is injected via spec 007's `LlmClock` so cooldown transitions are deterministic under test.
- Provider client failures come through the spec-007 `LlmClient` interface; a `FakeLlmClient` test helper scripts outcomes.
- The chain exhaustion error carries the per-provider errors for observability.

## Dependencies

- After: spec 007 (LLM provider clients)
- Feeds: spec 002 (engine loop uses fallback client)
