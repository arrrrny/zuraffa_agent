# Test List: 035-circuit-breaker

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | it is false — there is nothing to recover. | AC-1 | PENDING |
| A2 | it is false; at exactly 30s it is true (boundary included: `elapsed >= cooldown`). | AC-2 | PENDING |
| A3 | it is false — the probe is in flight, not due. | AC-3 | PENDING |
| A4 | the breaker stays CLOSED with `failureCount == 1` — the old streak did not survive recovery. | AC-4 | PENDING |
| A5 | it trips open again (a full fresh trip cycle). | AC-5 | PENDING |
| A6 | it re-trips open immediately with `halfOpenSuccesses == 0` and `openedAt` stamped at the failure. | AC-6 | PENDING |
| A7 | it is false and `shouldProbe(T+30s)` is true — the cooldown continued across the round-trip. | AC-7 | PENDING |
| A8 | the restored breaker is still halfOpen with `halfOpenSuccesses == 1` — one more success closes it (mid-probe resume). | AC-8 | PENDING |
| A9 | an `ArgumentError` names the offending field — never a silent default (a defaulted threshold would silently change trip behavior). | AC-9 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | The system MUST satisfy this requirement: The `CircuitBreaker` value object keeps its spec-exact nine-field surface and all transition semantics — `recordFailure`/`recordSuccess`/`tryHalfOpen` pure snapshot transitions, the `isOpen`/`isClosed`/`isHalfOpen` reads, value equality — unchanged (compile parity with the 12 existing tests). | FR-001 | PENDING |
| U2 | `shouldProbe(DateTime now)` MUST return true iff `state == open && openedAt != null && now.difference(openedAt) >= cooldown` (inclusive boundary); false otherwise (closed, halfOpen, open-with-null-openedAt). It is a pure read — it MUST NOT transition the breaker (calling `tryHalfOpen` remains the coordinator's job). | FR-002 | PENDING |
| U3 | The full recovery cycle MUST hold as a composed regression: trip (threshold failures) → cooldown → halfOpen → threshold successes → closed with `failureCount == 0`; a subsequent single failure stays closed with `failureCount == 1` (fresh streak); threshold fresh failures re-trip; a half-open failure re-trips open with `halfOpenSuccesses == 0` and `openedAt` stamped. | FR-003 | PENDING |
| U4 | `toJson()` MUST emit all nine fields — `id`, `state` (state name), `failureCount`, `failureThreshold`, `cooldown` (microseconds int), `halfOpenSuccesses`, `halfOpenThreshold` always; `openedAt`, `lastFailureAt` only when non-null (ISO-8601) — and `CircuitBreaker.fromJson` MUST round-trip every state exactly (incl. mid-probe halfOpen and open-with-cooldown-remaining), with restored cooldown semantics identical to the original. | FR-004 | PENDING |
| U5 | `fromJson` MUST throw `ArgumentError` naming the field on: missing/ill-typed required fields, unknown state string, negative counters, `failureThreshold`/`halfOpenThreshold` < 1, `cooldown` <= 0, or unparseable timestamps — never a silent default. | FR-005 | PENDING |
| U6 | The system MUST satisfy this requirement: The clean-arch layers (`CircuitBreakerService.current/count`, `CircuitBreakerProvider`) keep their existing signatures and stubs (no behavioral change). | FR-006 | PENDING |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 26]
route: A2 -> acceptance lane [declared: type marker, spec line 28]
route: A3 -> acceptance lane [declared: type marker, spec line 30]
route: A4 -> acceptance lane [declared: type marker, spec line 45]
route: A5 -> acceptance lane [declared: type marker, spec line 47]
route: A6 -> acceptance lane [declared: type marker, spec line 49]
route: A7 -> acceptance lane [declared: type marker, spec line 64]
route: A8 -> acceptance lane [declared: type marker, spec line 66]
route: A9 -> acceptance lane [declared: type marker, spec line 68]
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U6 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

