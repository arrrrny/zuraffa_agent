# Feature Specification: RepetitionTracker datasource + mock pair

**Feature Branch**: `25-repetition_tracker-datasource-pair`

**Created**: 2026-08-24 | **Refined**: 2026-08-27 via /speckit.specify (drift remediation)

**Status**: Approved

**Input**: Verbatim task spec — "repetition tracker datasource pair. Existing: lib/src/data/datasources/repetition_tracker/* (interface + mock), lib/src/domain/entities/repetition_tracker/repetition_tracker.dart. Spec + tests: track repeated tool/LLM calls to detect loops; interface + mock + entity parity; persistence contract."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Detect a runaway tool loop (Priority: P1)

As the engine loop, I feed every tool/LLM invocation signature to the repetition tracker so that when the same signature is recorded more than N times within a sliding M-second window, I get a positive loop signal and can abort the mission with a typed `LoopDetected` outcome (spec 002 US4).

**Why this priority**: Agent loops without rails hang and burn budget (spec 002 §US4 "Why this priority"). Loop detection is the single behavior the whole datasource pair exists to serve; everything else supports it.

**Independent Test**: Call `record(signature)` N+1 times against the mock datasource with a fixed clock; `isLooping(signature)` must flip from false to true exactly at the configured `maxCalls` threshold.

**Acceptance Scenarios**:

1. **Given** a tracker configured `maxCalls=3, window=60s`, **When** the same signature is recorded 2 times, **Then** `isLooping` is false and `count` returns 2.
2. **Given** the same tracker, **When** the same signature is recorded a 3rd time, **Then** `isLooping` is true (threshold met — "more than N times in the last M seconds" is inclusive of the Nth hit).
3. **Given** two different signatures recorded 3 times each with `maxCalls=3`, **Then** both loop independently — counts are keyed per signature, never shared.

---

### User Story 2 - Window expiry keeps old calls from poisoning the signal (Priority: P2)

As the engine loop, I need calls older than the window to stop counting, so that a tool legitimately re-invoked across a long mission (e.g. `read_file` every 90 s) is not misjudged as a loop.

**Why this priority**: Without window pruning the tracker degrades into a lifetime call counter and every long mission false-positives.

**Independent Test**: Record `maxCalls` occurrences at T0; advance the injected clock beyond `window`; `count` must return 0 and `isLooping` must be false.

**Acceptance Scenarios**:

1. **Given** `window=60s` and 3 records at `T0`, **When** `count`/`isLooping` are evaluated at `T0+61s`, **Then** count is 0 and no loop is signalled.
2. **Given** records at `T0` and `T0+50s` with `window=60s`, **When** evaluated at `T0+61s`, **Then** only the second record counts (boundary: exactly `window` old is expired; strictly inside is alive).

---

### User Story 3 - Persistence contract for real backends (Priority: P3)

As the application integrator, I replace the mock with a Hive/remote-backed implementation of the same interface (`current`, `reset`, `record`, `count`, `isLooping`) without touching the engine, and `reset()` restores the tracker to a clean slate mid-mission (e.g. after a steering correction).

**Why this priority**: The datasource pair is the seam that keeps the engine free of storage concerns; the contract must be pinned by tests so any backend can be swapped in.

**Independent Test**: Implement the interface in a test double delegating to an in-memory map; all spec-25 behaviors pass unchanged through it; `reset()` clears all recorded history while preserving configuration.

**Acceptance Scenarios**:

1. **Given** a mock with 3 recorded signatures, **When** `reset()` is called, **Then** all counts drop to 0, no signature loops, and `current()` still returns the same configuration.
2. **Given** any conforming implementation, **When** `record` returns, **Then** it returns the post-record in-window count for that signature (single round-trip read-after-write).

### Edge Cases

- What happens when `maxCalls <= 0`? → The entity constructor asserts `maxCalls >= 1`; a non-positive threshold is a configuration error, not a runtime loop signal.
- What happens when records arrive out of clock order? → Pruning uses each record's own timestamp against evaluation time; late records older than the window are pruned on first evaluation.
- What happens on `record` for a never-seen signature? → Count starts at 1; no pre-registration is required.
- What happens to the loop signal after the window expires? → `isLooping` reverts to false (signal is derived, never sticky).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The `RepetitionTracker` value object MUST expose the loop-detection configuration — `id`, `maxCalls` (N), `window` (M) — with value equality across all fields.
- **FR-002**: `RepetitionTracker` MUST expose a pure predicate `isRepetition(observedCalls)` that returns true iff `observedCalls >= maxCalls`, so threshold logic is testable without a datasource.
- **FR-003**: The datasource interface MUST define the persistence contract: `current()`, `reset()`, `record(signature)`, `count(signature)`, `isLooping(signature)` — all asynchronous.
- **FR-004**: `record` MUST accept an optional injectable timestamp; `count`/`isLooping` MUST accept an optional injectable evaluation time, so window behavior is deterministically testable.
- **FR-005**: The mock datasource MUST implement in-memory sliding-window tracking: per-signature timestamp lists, pruned to the window at write and read time.
- **FR-006**: `isLooping(signature)` MUST equal `current().isRepetition(count(signature))` — the signal is always derived from the live window count and the configured threshold.
- **FR-007**: `reset()` MUST clear every recorded signature history while preserving the tracker configuration returned by `current()`.
- **FR-008**: The entity, interface, and mock MUST keep constructor backward compatibility: `RepetitionTracker({required id})` and `RepetitionTrackerMockDatasource()` must keep compiling with sensible defaults (`maxCalls=5`, `window=60s`).

### Key Entities *(include if feature involves data)*

- **RepetitionTracker** (value object): loop-detection policy — `id`, `maxCalls`, `window`; pure `isRepetition` predicate. No mutable state.
- **RepetitionTrackerDatasource** (interface): persistence contract over the tracker — read config, reset, record a call, count in-window calls, derive loop signal.
- **RepetitionTrackerMockDatasource** (concrete): in-memory implementation with injectable clock for deterministic tests.
- **ToolCallSignature** (owned by spec 29): the signature string passed to `record` is the canonical key a `ToolCallSignature` produces; this pair consumes it as an opaque `String`, keeping the two specs independently testable.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Recording the same signature `maxCalls` times makes `isLooping` true; `maxCalls-1` times keeps it false — proved by tests at both boundaries (AC US1).
- **SC-002**: After advancing the injectable clock past `window`, `count` is 0 and `isLooping` is false (AC US2).
- **SC-003**: `reset()` zeroes all counts and preserves configuration (AC US3).
- **SC-004**: Entity parity — two `RepetitionTracker`s with equal fields are `==`, have equal `hashCode`, and different fields make them unequal.
- **SC-005**: `dart analyze` reports zero new issues; full `dart test` suite green (baseline: 529 passed / 5 pre-existing analyze issues).

## Assumptions

- "More than N times in the last M seconds" is interpreted inclusively: the Nth in-window occurrence trips the signal (matches spec 002 US4 scenario 2 where hitting the threshold fires `LoopDetected`).
- Default configuration `maxCalls=5, window=60s` aligns with the StopPolicy default `repetitionThreshold=5` already documented on `StopPolicyService.defaultPolicy`.
- Persistence here means the interface contract; an actual Hive/remote backend is out of scope for this feature (the mock is the reference implementation).
- Existing regression tests asserting `UnimplementedError` stubs are superseded by this refinement: the pair now ships real behavior (documented as drift remediation).
