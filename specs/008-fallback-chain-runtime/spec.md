# Feature Specification: Fallback Chain Runtime

**Feature Branch**: `008-fallback-chain-runtime`

**Created**: 2026-08-27

**Status**: Draft

**Input**: Gap analysis vs dart_agent_core — entity stubs exist but no runtime logic for fallback, circuit breaker, or health tracking.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Fallback on provider failure (Priority: P1)

As the engine operator, I configure an ordered provider chain (e.g., self-host → frontier). On connection error, timeout, 5xx, context overflow, or repeated 429, the chain advances transparently.

**Why this priority**: BFCM-scale availability: one provider outage must not kill missions.

**Independent Test**: Outage fixtures trip the breaker on provider A, transparently serve via B, then A half-open probes and recovers.

**Acceptance Scenarios**:

1. **Given** provider A failing, **When** a call is made, **Then** B serves it; the mission observes only latency.
2. **Given** A in open state, **When** the cooldown elapses, **Then** a half-open probe routes real traffic back on success.
3. **Given** a mid-stream failure after partial chunks, **Then** the policy restarts on the next provider — never silently truncates.

### User Story 2 - Circuit breaker per provider (Priority: P1)

As the engine, each provider has an independent circuit breaker (open/half-open/closed) with configurable failure threshold and cooldown.

**Why this priority**: Prevents cascading failures and enables automatic recovery.

**Independent Test**: A provider that fails 3 times opens the circuit; after cooldown, a successful call closes it.

**Acceptance Scenarios**:

1. **Given** maxConsecutiveFailures=3, **When** 3 consecutive failures occur, **Then** the breaker opens.
2. **Given** an open breaker with cooldownMs=60000, **When** 60s elapses, **Then** the state transitions to half-open.
3. **Given** a half-open breaker, **When** a call succeeds, **Then** the state transitions to closed.

### User Story 3 - Health snapshot (Priority: P2)

As an operator/dashboard, I query `Map<provider, ClientHealth>` at any time to see breaker states, failure counts, and cooldown status.

**Why this priority**: Observability for the fallback chain at scale.

**Independent Test**: Breaker transitions are reflected in the snapshot immediately.

**Acceptance Scenarios**:

1. **Given** any chain state, **When** the snapshot is read, **Then** it matches the internal breaker states.

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

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Outage fixtures trip and recover the breaker; mid-stream policy explicit.
- **SC-002**: Health snapshot reflects breaker states in real-time.

## Dependencies

- After: spec 007 (LLM provider clients)
- Feeds: spec 002 (engine loop uses fallback client)
