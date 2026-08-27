# Feature Specification: CircuitBreaker state machine (R4 providers & fallback) — recovery readiness + persistence contract

**Feature Branch**: `feat/specs-032-033-034-035` (spec dir: `035-circuit-breaker`)

**Created**: 2026-08-24 | **Refined**: 2026-08-27 via /speckit.specify (drift remediation)

**Status**: Approved

**Input**: Verbatim task spec — "035-circuit-breaker — LLM circuit breaker (closed/half-open/open states, failure threshold, cooldown/recovery). Existing: lib/src/llm/circuit_breaker.dart, lib/src/data/providers/circuit_breaker/circuit_breaker_provider.dart, lib/src/domain/services/circuit_breaker_service.dart, lib/src/domain/entities/circuit_breaker/circuit_breaker.dart. Spec + tests for state transitions and recovery."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The engine asks the breaker before every provider call (Priority: P1)

As the fallback-chain coordinator, before attempting a provider I consult the breaker: a closed or half-open breaker permits the attempt, an open breaker fail-fasts the skip to the next provider — and when an open breaker's cooldown has elapsed, I learn that it is ready for a half-open probe (the `tryHalfOpen` transition is the coordinator's to call; the breaker must be able to SAY when it is due).

**Why this priority**: The task names "cooldown/recovery" — the recovery decision (when to probe) is currently implicit inside `tryHalfOpen`'s elapsed check; a coordinator deciding WHICH provider to attempt next has no read-side predicate, so every consumer re-derives `now.difference(openedAt!) >= cooldown` by hand (fragile: it must remember the null `openedAt` case and the halfOpen reset). The scaffold's doc even assigns the engine the responsibility of "calling the right transition at the right time" — without a `shouldProbe` read, "the right time" is undocumented API.

**Independent Test**: `shouldProbe(now)` is false in closed/halfOpen, false in open before cooldown elapses (one tick before the boundary), true at and after the boundary.

**Acceptance Scenarios**:

1. **Given** a closed breaker (any counters), **When** `shouldProbe` is asked, **Then** it is false — there is nothing to recover.
2. **Given** an open breaker with `openedAt` 29s ago and a 30s cooldown, **When** `shouldProbe` is asked, **Then** it is false; at exactly 30s it is true (boundary included: `elapsed >= cooldown`).
3. **Given** a half-open breaker (already probing), **When** `shouldProbe` is asked, **Then** it is false — the probe is in flight, not due.

---

### User Story 2 - Recovery is a full cycle that resets the failure streak (Priority: P1)

As the fallback-chain coordinator, when a tripped breaker recovers (open → halfOpen → threshold successes → closed), the breaker starts a fresh failure streak — the next trip requires `failureThreshold` NEW consecutive failures, not the residue of the old one — and a half-open failure re-trips immediately with the probe counters reset.

**Why this priority**: This is the R4.3 "open/half-open/close with backoff" heart. The scaffold's transition methods implement it, and the 12 existing provider tests pin the individual transitions; what is missing is the full-cycle regression (the composition): recovery → fresh streak → re-trip, and the half-open failure re-trip with reset. Without the composed test, a future refactor could keep every unit transition green while breaking the cycle (e.g. failureCount leaking across recovery).

**Independent Test**: closed → 3 failures → open; cooldown → halfOpen; 2 successes → closed with `failureCount == 0`; one more failure → closed with `failureCount == 1` (fresh streak, NOT a re-trip); 3 more failures → open again.

**Acceptance Scenarios**:

1. **Given** a breaker recovered via halfOpen (halfOpenThreshold successes), **When** a single failure lands, **Then** the breaker stays CLOSED with `failureCount == 1` — the old streak did not survive recovery.
2. **Given** that recovered breaker, **When** `failureThreshold` consecutive failures land, **Then** it trips open again (a full fresh trip cycle).
3. **Given** a half-open breaker with partial probe successes, **When** a failure lands, **Then** it re-trips open immediately with `halfOpenSuccesses == 0` and `openedAt` stamped at the failure.

---

### User Story 3 - Breaker state survives the restart boundary (Priority: P2)

As the persistence layer (health snapshots, chain state across process restarts), I serialize the breaker snapshot to JSON and parse it back without losing the state, counters, thresholds, or timestamps — so an open breaker restored after a restart continues its cooldown from the original `openedAt`, and a mid-probe breaker resumes with its partial `halfOpenSuccesses`.

**Why this priority**: "Recovery" in the task names spans restarts: a fallback chain that forgets its breaker state after a restart re-hammers a dead provider. The scaffold has no serialization. Precedent: specs 031/032/033/034 each landed `toJson`/`fromJson` for exactly this boundary.

**Independent Test**: `CircuitBreaker.fromJson(b.toJson()) == b` for every state (closed with counters, open with timestamps, halfOpen mid-probe); a restored open breaker's cooldown continues from the original `openedAt` (`shouldProbe` agrees before and after the round-trip).

**Acceptance Scenarios**:

1. **Given** an open breaker (openedAt T, cooldown 30s), **When** serialized at T+10s, parsed, and asked `shouldProbe(T+29s)`, **Then** it is false and `shouldProbe(T+30s)` is true — the cooldown continued across the round-trip.
2. **Given** a half-open breaker with `halfOpenSuccesses == 1` (threshold 2), **When** serialized and parsed, **Then** the restored breaker is still halfOpen with `halfOpenSuccesses == 1` — one more success closes it (mid-probe resume).
3. **Given** malformed JSON (missing id/thresholds/cooldown, negative counters, unknown state string, unparseable timestamps), **When** parsed, **Then** an `ArgumentError` names the offending field — never a silent default (a defaulted threshold would silently change trip behavior).

### Edge Cases

- `shouldProbe` on an open breaker with null `openedAt` (constructible, though unreachable via transitions) → false, defensive (the scaffold's `tryHalfOpen` already guards this; the read side must agree).
- Cooldown boundary is INCLUSIVE (`elapsed >= cooldown`) — pinned on both sides (one tick before: false; at the boundary: true).
- Malformed JSON: negative `failureThreshold`/`halfOpenThreshold` or non-positive `cooldown` → `ArgumentError` (the scaffold's docs say "must be > 0"; parse is the enforcement point).
- `openedAt`/`lastFailureAt` serialize only when non-null (absent-never-fabricated).
- The `Duration` serializes as microseconds (exact round-trip; no float drift).
- Escalating backoff (cooldown doubling per re-trip): NOT in scope — the epic's "with backoff" is read as the fixed cooldown (the task input names "cooldown/recovery", not escalation); a future feature may extend.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The `CircuitBreaker` value object keeps its spec-exact nine-field surface and all transition semantics — `recordFailure`/`recordSuccess`/`tryHalfOpen` pure snapshot transitions, the `isOpen`/`isClosed`/`isHalfOpen` reads, value equality — unchanged (compile parity with the 12 existing tests).
- **FR-002**: `shouldProbe(DateTime now)` MUST return true iff `state == open && openedAt != null && now.difference(openedAt) >= cooldown` (inclusive boundary); false otherwise (closed, halfOpen, open-with-null-openedAt). It is a pure read — it MUST NOT transition the breaker (calling `tryHalfOpen` remains the coordinator's job).
- **FR-003**: The full recovery cycle MUST hold as a composed regression: trip (threshold failures) → cooldown → halfOpen → threshold successes → closed with `failureCount == 0`; a subsequent single failure stays closed with `failureCount == 1` (fresh streak); threshold fresh failures re-trip; a half-open failure re-trips open with `halfOpenSuccesses == 0` and `openedAt` stamped.
- **FR-004**: `toJson()` MUST emit all nine fields — `id`, `state` (state name), `failureCount`, `failureThreshold`, `cooldown` (microseconds int), `halfOpenSuccesses`, `halfOpenThreshold` always; `openedAt`, `lastFailureAt` only when non-null (ISO-8601) — and `CircuitBreaker.fromJson` MUST round-trip every state exactly (incl. mid-probe halfOpen and open-with-cooldown-remaining), with restored cooldown semantics identical to the original.
- **FR-005**: `fromJson` MUST throw `ArgumentError` naming the field on: missing/ill-typed required fields, unknown state string, negative counters, `failureThreshold`/`halfOpenThreshold` < 1, `cooldown` <= 0, or unparseable timestamps — never a silent default.
- **FR-006**: The clean-arch layers (`CircuitBreakerService.current/count`, `CircuitBreakerProvider`) keep their existing signatures and stubs (no behavioral change).

### Key Entities *(include if feature involves data)*

- **CircuitBreaker** (value object, existing scaffold): nine-field surface + transitions (existing, pinned) + NEW `shouldProbe` read + NEW `toJson`/`fromJson`.
- **CircuitBreakerService / CircuitBreakerProvider** (existing interfaces): unchanged surfaces; compile parity pinned by the existing 12 tests.
- NOT modified: `lib/src/llm/circuit_breaker.dart` (the LLM-layer runtime breaker — a separate concern from the domain value object; see Assumptions).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `shouldProbe` answers correctly in every state, on both sides of the cooldown boundary, and never transitions (AC US1-1..3).
- **SC-002**: the full recovery cycle holds — fresh streak after recovery, re-trip after fresh threshold, half-open failure re-trip with reset (AC US2-1..3).
- **SC-003**: every state round-trips JSON field-exactly; a restored open breaker continues its cooldown (AC US3-1).
- **SC-004**: mid-probe halfOpen resumes with partial `halfOpenSuccesses` (AC US3-2).
- **SC-005**: malformed JSON fails typed, naming the field (AC US3-3, edge-3).
- **SC-006**: `dart analyze --fatal-infos` zero new issues; full `dart test` green (post-034 baseline 640 passed); the 12 pre-existing provider tests pass unchanged (FR-001, FR-006).

## Assumptions

- `shouldProbe` is additive (scaffold surface untouched) and deliberately read-only: the transition stays the coordinator's call (mirrors the scaffold doc: "the engine... is responsible for calling the right transition at the right time"). This closes the documented-but-missing read side of that contract.
- `lib/src/llm/circuit_breaker.dart` is a separate LLM-runtime breaker (its own spec family — 007/008 territory); this feature refines ONLY the domain value object the task's file list centers on (`lib/src/domain/entities/circuit_breaker/`), per the repo spec.md's Files section.
- The full-cycle regression (FR-003) is a characterization of EXISTING scaffold behavior composed into a cycle — it lands green-on-scaffold by design (a regression pin, not a bug fix); the genuinely red surfaces are `shouldProbe` and the serialization (absent from the scaffold).
- `Duration` serializes as integer microseconds (exact, drift-free); timestamps as ISO-8601 strings (UTC instants round-trip exactly).
- Escalating backoff is out of scope (documented edge — the epic's "backoff" is read as the fixed cooldown).
- The provider/service layers stay stubs in this feature (FR-006).
- The scaffold's `hashCode` (all-scalar fields through `Object.hash`) already satisfies the ==/hashCode contract — no hash remediation needed.
