# Feature Specification: StopPolicy datasource + mock pair

**Feature Branch**: `27-stop_policy-datasource-pair`

**Created**: 2026-08-24 | **Refined**: 2026-08-27 via /speckit.specify (drift remediation)

**Status**: Approved

**Input**: Verbatim task spec — "stop policy datasource pair. Existing: lib/src/data/datasources/stop_policy/*, lib/src/data/providers/stop_policy/stop_policy_provider.dart, lib/src/domain/repositories/stop_policy_repository.dart, lib/src/domain/services/stop_policy_service.dart, lib/src/domain/entities/stop_policy/stop_policy.dart. Spec + tests for the datasource pair and how the service/repository consume it."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The engine reads the live stop policy (Priority: P1)

As the engine loop, I read the currently active StopPolicy (max turns, wall-clock timeout, repetition threshold, enabled) through the service/repository/datasource chain, so every turn's stop checks use the latest persisted policy without the engine knowing where it is stored.

**Why this priority**: The stop policy is the safety surface bounding every mission (spec 002 US4); reading it correctly through the clean-arch chain is the load-bearing behavior all other stories build on.

**Independent Test**: Seed the mock datasource with a policy; `StopPolicyProvider.current(NoParams())` must return exactly that policy through the datasource.

**Acceptance Scenarios**:

1. **Given** a fresh chain wired over the mock datasource, **When** `current` is called, **Then** the default policy is returned (`maxTurns=100`, `wallClockTimeout=0`, `repetitionThreshold=5`, `enabled=true`, `id='default'`).
2. **Given** a policy persisted via `update`, **When** `current` is called, **Then** the updated policy is returned — the read always reflects the last write.

---

### User Story 2 - Operators update and reset the policy (Priority: P2)

As the engine operator, I tighten the policy before a risky mission (lower `maxTurns`) and reset it back to the default afterwards, so the same deployment serves missions with different risk profiles.

**Why this priority**: Read-only policy is a fixture, not a feature; update + reset is what makes the pair a persistence contract rather than a constant.

**Independent Test**: `update(strict)` then `current()` returns `strict`; `reset()` then `current()` returns the documented default.

**Acceptance Scenarios**:

1. **Given** any current policy, **When** `update(policy)` completes, **Then** `current()` returns a policy equal to the one written (full replace; value objects are immutable).
2. **Given** a non-default policy active, **When** `reset()` is called, **Then** `current()` returns the default policy and any subsequent `update` starts again from a clean state.

---

### User Story 3 - The chain consumes the datasource through the repository seam (Priority: P3)

As the application integrator, I swap the mock datasource for a Hive/remote-backed implementation and the service/repository/provider layers keep working unchanged, because they depend only on the datasource interface.

**Why this priority**: The datasource pair is the seam that keeps storage out of the engine; the wiring must be pinned by tests so backends can be replaced.

**Independent Test**: A repository implementation built over any conforming datasource passes the same read/update/reset behaviors; the provider consumes the datasource through its interface (constructor-injectable), never a concrete implementation.

**Acceptance Scenarios**:

1. **Given** the provider is constructed over a datasource, **When** any service method is called, **Then** the call is served by that datasource (observable through returned state); the repository consumes the same datasource for id-keyed access.
2. **Given** `getCurrent` is called with an id that matches no stored policy, **Then** a typed error surfaces (no silent default substitution — a wrong-id read is a wiring bug).

### Edge Cases

- What happens when `getCurrent` targets an unknown id? → `StateError` (typed, non-silent) — the repository is keyed by policy id for a single-instance value object.
- What happens when `update` stores a policy whose id differs from the stored one? → Full replace wins: the store keeps exactly the policy passed (value-object semantics), so subsequent `getCurrent(oldId)` raises `StateError`.
- What happens when `enabled=false`? → The policy is inert at the engine level (spec 002); the datasource pair stores and returns it verbatim — enforcement is out of scope for the pair.
- What is the reset target? → The documented default policy (single source of truth: `StopPolicy.defaultPolicy`).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The `StopPolicy` value object MUST expose the spec-002-exact surface (`id`, `maxTurns`, `wallClockTimeout`, `repetitionThreshold`, `enabled`) with value equality, and MUST carry the canonical default (`maxTurns=100`, `wallClockTimeout=0`, `repetitionThreshold=5`, `enabled=true`) as a single constant.
- **FR-002**: The datasource interface MUST define the persistence contract for the single-instance value object: `current()`, `update(policy)`, `reset()` — all asynchronous.
- **FR-003**: The mock datasource MUST implement the contract in memory: seeded with the default, `update` fully replaces, `reset` restores the default, `current` returns the live value.
- **FR-004**: A concrete repository (`StopPolicyRepositoryImpl`) MUST implement the domain `StopPolicyRepository` (`getCurrent(id)`, `update(policy)`, `reset(id)`) by delegating to the datasource, raising `StateError` on an id mismatch.
- **FR-005**: The provider MUST implement the domain `StopPolicyService` (`current(NoParams)`, `defaultPolicy(NoParams)`) by consuming the datasource's id-less `current()` for the live policy (the service surface is id-less by design — `NoParams`), and by returning the canonical default constant for `defaultPolicy`. The repository remains the id-keyed domain-facing seam over the same datasource; both consume the datasource.
- **FR-006**: Constructor backward compatibility MUST hold: `StopPolicyProvider()` and `StopPolicyMockDatasource()` parameterless constructions keep compiling; the provider defaults its wiring to a fresh mock datasource.

### Key Entities *(include if feature involves data)*

- **StopPolicy** (value object): stop-condition policy — unchanged field surface from the hand-curated entity, plus the canonical `defaultPolicy` constant.
- **StopPolicyDatasource** (interface): single-instance persistence contract — read, replace, restore-default.
- **StopPolicyMockDatasource** (concrete): in-memory implementation seeded with the default.
- **StopPolicyRepository / StopPolicyRepositoryImpl** (domain interface / data implementation): id-keyed gateway over the datasource.
- **StopPolicyService / StopPolicyProvider** (domain interface / data implementation): the engine-facing surface — current policy + canonical default.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: read-after-update: `update(p)` then `current()` returns `p` (AC US2-1).
- **SC-002**: reset restores the documented default through the whole chain (AC US2-2).
- **SC-003**: the provider serves the id-less read through the datasource — a policy seeded into the datasource is returned by `StopPolicyProvider.current(NoParams())` (AC US1-2, US3-1); the repository serves the id-keyed reads over the same datasource (AC US3-2).
- **SC-004**: unknown-id reads raise `StateError` (AC US3-2, edge-1).
- **SC-005**: `dart analyze` zero new issues; full `dart test` green (post-spec-25 baseline: 544 passed / 5 pre-existing analyze issues).

## Assumptions

- The wall-clock timeout field stays `Duration` (issue #13 — zfa cannot generate it; the hand-curated entity is canonical).
- "Token budget" from the original stub wording is realized as the existing four-field surface (maxTurns / wallClockTimeout / repetitionThreshold / enabled) — spec 002's data model lists exactly these; no new field is added.
- Enforcement of stop conditions (comparing turn counts against `maxTurns`, firing typed outcomes) belongs to the engine loop (spec 002/046), NOT to the datasource pair — the pair only persists and serves the policy.
- The default policy values are frozen by the existing `StopPolicyService.defaultPolicy` documentation; this feature makes `StopPolicy.defaultPolicy` the single source of truth for them.
- Existing tests asserting provider `UnimplementedError` stubs are superseded (drift remediation) — the provider now ships real delegation.
