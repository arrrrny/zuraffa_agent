# Traceability: 035-circuit-breaker

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:01091ac9574e3319cfb7f12e52f14b8ffea9c791bdfa428b13427057727ff481
statements: 15
automated: 15
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 25 | 1. **Given** a closed breaker (any counters), **When** `shouldProbe` is asked, **Then** it is false — there is nothing to recover. | A1 | automated |
| AC-2 | 27 | 2. **Given** an open breaker with `openedAt` 29s ago and a 30s cooldown, **When** `shouldProbe` is asked, **Then** it is false; at exactly 30s it is true (boundary included: `elapsed >= cooldown`). | A2 | automated |
| AC-3 | 29 | 3. **Given** a half-open breaker (already probing), **When** `shouldProbe` is asked, **Then** it is false — the probe is in flight, not due. | A3 | automated |
| AC-4 | 44 | 4. **Given** a breaker recovered via halfOpen (halfOpenThreshold successes), **When** a single failure lands, **Then** the breaker stays CLOSED with `failureCount == 1` — the old streak did not survive recovery. | A4 | automated |
| AC-5 | 46 | 5. **Given** that recovered breaker, **When** `failureThreshold` consecutive failures land, **Then** it trips open again (a full fresh trip cycle). | A5 | automated |
| AC-6 | 48 | 6. **Given** a half-open breaker with partial probe successes, **When** a failure lands, **Then** it re-trips open immediately with `halfOpenSuccesses == 0` and `openedAt` stamped at the failure. | A6 | automated |
| AC-7 | 63 | 7. **Given** an open breaker (openedAt T, cooldown 30s), **When** serialized at T+10s, parsed, and asked `shouldProbe(T+29s)`, **Then** it is false and `shouldProbe(T+30s)` is true — the cooldown continued across the round-trip. | A7 | automated |
| AC-8 | 65 | 8. **Given** a half-open breaker with `halfOpenSuccesses == 1` (threshold 2), **When** serialized and parsed, **Then** the restored breaker is still halfOpen with `halfOpenSuccesses == 1` — one more success closes it (mid-probe resume). | A8 | automated |
| AC-9 | 67 | 9. **Given** malformed JSON (missing id/thresholds/cooldown, negative counters, unknown state string, unparseable timestamps), **When** parsed, **Then** an `ArgumentError` names the offending field — never a silent default (a defaulted threshold would silently change trip behavior). | A9 | automated |
| FR-001 | 83 | - **FR-001**: The system MUST satisfy this requirement: The `CircuitBreaker` value object keeps its spec-exact nine-field surface and all transition semantics — `recordFailure`/`recordSuccess`/`tryHalfOpen` pure snapshot transitions, the `isOpen`/`isClosed`/`isHalfOpen` reads, value equality — unchanged (compile parity with the 12 existing tests). | U1 | automated |
| FR-002 | 84 | - **FR-002**: `shouldProbe(DateTime now)` MUST return true iff `state == open && openedAt != null && now.difference(openedAt) >= cooldown` (inclusive boundary); false otherwise (closed, halfOpen, open-with-null-openedAt). It is a pure read — it MUST NOT transition the breaker (calling `tryHalfOpen` remains the coordinator's job). | U2 | automated |
| FR-003 | 85 | - **FR-003**: The full recovery cycle MUST hold as a composed regression: trip (threshold failures) → cooldown → halfOpen → threshold successes → closed with `failureCount == 0`; a subsequent single failure stays closed with `failureCount == 1` (fresh streak); threshold fresh failures re-trip; a half-open failure re-trips open with `halfOpenSuccesses == 0` and `openedAt` stamped. | U3 | automated |
| FR-004 | 86 | - **FR-004**: `toJson()` MUST emit all nine fields — `id`, `state` (state name), `failureCount`, `failureThreshold`, `cooldown` (microseconds int), `halfOpenSuccesses`, `halfOpenThreshold` always; `openedAt`, `lastFailureAt` only when non-null (ISO-8601) — and `CircuitBreaker.fromJson` MUST round-trip every state exactly (incl. mid-probe halfOpen and open-with-cooldown-remaining), with restored cooldown semantics identical to the original. | U4 | automated |
| FR-005 | 87 | - **FR-005**: `fromJson` MUST throw `ArgumentError` naming the field on: missing/ill-typed required fields, unknown state string, negative counters, `failureThreshold`/`halfOpenThreshold` < 1, `cooldown` <= 0, or unparseable timestamps — never a silent default. | U5 | automated |
| FR-006 | 88 | - **FR-006**: The system MUST satisfy this requirement: The clean-arch layers (`CircuitBreakerService.current/count`, `CircuitBreakerProvider`) keep their existing signatures and stubs (no behavioral change). | U6 | automated |

