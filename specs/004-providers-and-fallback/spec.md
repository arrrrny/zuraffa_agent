# Feature Specification: Providers & Fallback Chain

**Feature Branch**: `004-providers-and-fallback`

**Created**: 2026-08-18

**Status**: Draft

**Input**: Epic arrrrny/zuraffa_agent#1 §R4 — converted from issue #5. Provider clients ported from dart_agent_core (MIT, vendored with attribution); the engine keeps zero external agent dependencies.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Provider clients, ported and owned (Priority: P1)

As the engine, I offer LLM clients for OpenAI-compatible (covers zikzak-ai self-host, Kimi, most), Anthropic, and Gemini — protocol logic ported from dart_agent_core, vendored with attribution headers, then owned.

**Why this priority**: No providers, no engine; porting (not depending) keeps the zero-dependency guarantee.

**Independent Test**: All three providers pass one shared contract-test suite (streaming, tool calls, usage parsing) over recorded-response fixtures.

**Acceptance Scenarios**:

1. **Given** recorded provider fixtures, **When** each client streams, **Then** events, tool-call buffering, and usage fields parse identically across providers.
2. **Given** the engine's pubspec, **When** resolved, **Then** dart_agent_core is absent; vendored files carry attribution.

### User Story 2 - Usage accounting (Priority: P2)

As the engine, every LLM call records token usage into the `UsageLedger` (spec 002) — input, output, cached — per call, per provider.

**Why this priority**: Budgets (plugin MissionBudgetHook) and cost telemetry consume the ledger.

**Independent Test**: A mixed-provider mission produces a ledger whose totals equal the sum of fixture usage fields.

**Acceptance Scenarios**:

1. **Given** any completed LLM call, **When** inspected, **Then** its ledger entry exists with provider + model + token counts.

### User Story 3 - Fallback chain with circuit breaker (Priority: P1)

As the engine operator, I configure an ordered provider chain (e.g., self-host → frontier). On connection error, timeout, 5xx, context overflow, or repeated 429, the chain advances; a circuit breaker opens per-provider after N consecutive failures (backoff, half-open probe) and recovers (supersedes arrrrny/dart_agent_core#1).

**Why this priority**: BFCM-scale availability: one provider outage must not kill missions.

**Independent Test**: Outage fixtures trip the breaker on provider A, transparently serve via B, then A half-open probes and recovers.

**Acceptance Scenarios**:

1. **Given** provider A failing, **When** a call is made, **Then** B serves it; the mission observes only latency.
2. **Given** A in open state, **When** the cooldown elapses, **Then** a half-open probe routes real traffic back on success.
3. **Given** a mid-stream failure after partial chunks, **Then** the policy restarts on the next provider (or surfaces, per config) — never silently truncates.

### User Story 4 - Health snapshot (Priority: P3)

As an operator/dashboard, I query `Map<provider, ClientHealth>` (state, failure counts, cooldown remaining) at any time.

**Why this priority**: Observability for the fallback chain at scale.

**Independent Test**: Breaker transitions are reflected in the snapshot immediately.

**Acceptance Scenarios**:

1. **Given** any chain state, **When** the snapshot is read, **Then** it matches the internal breaker states.

### Edge Cases

- Context overflow on provider A (window too small) → classified as advance-able, not retried on A.
- All providers open → typed `AllProvidersUnavailable`; mission fails gracefully with salvage (loop spec).
- Fixture-less provider (no recordings) in CI → contract suite skips with explicit notice, never passes silently.
- SSE keepalive/comments differing per provider → parser normalizes.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The engine MUST provide OpenAI-compatible, Anthropic, and Gemini clients behind one `LlmClient` interface on engine primitives.
- **FR-002**: Provider code MUST be vendored from dart_agent_core with attribution; dart_agent_core MUST NOT appear in the dependency graph.
- **FR-003**: Every call MUST account usage into the UsageLedger.
- **FR-004**: A fallback chain MUST advance on connection/timeout/5xx/context-overflow/repeated-429 with per-provider circuit breaker (open/half-open/closed) and explicit mid-stream policy.
- **FR-005**: A health snapshot API MUST expose chain state.

### Key Entities

- **LlmClient** (interface): stream(messages, tools, config) → events; ported implementations.
- **FallbackChain**: ordered clients + breaker state machine + policy knobs.
- **ClientHealth**: state, consecutive failures, cooldown window.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All providers pass shared contract tests on record/replay fixtures (issue #5 AC).
- **SC-002**: Outage fixtures trip and recover the breaker; mid-stream policy explicit (AC).
- **SC-003**: dart_agent_core absent from pubspec; vendored code attributed (AC).
- **SC-004**: Self-hosted zikzak-ai (OpenAI-compatible) verified live (AC).

## Assumptions

- Anthropic/Gemini support real-but-secondary priority; OpenAI-compatible is the workhorse (self-host + Kimi).
- Live verification (SC-004) runs against a staging endpoint, not production keys.

## Dependencies

- Issue: arrrrny/zuraffa_agent#5 · Epic: #1 · After: spec 001 (loop consumes clients) · Feeds: zik_zak touchpoint migration (arrrrny/zik_zak#173 stopgap skippable if this lands first)
