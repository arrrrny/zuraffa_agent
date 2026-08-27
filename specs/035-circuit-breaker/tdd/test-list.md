---
feature: 035-circuit-breaker
loop: inside-out
profile: .specify/memory/tdd-profile.md
spec_criteria: 9 # acceptance criteria AC US1-1..3, US2-1..3, US3-1..3 in spec.md
planned_at: 727c618
updated_at: 727c618
suite_baseline: green # 640 passed, 0 failed (post spec-034)
---

# Test List: CircuitBreaker state machine — recovery readiness + persistence contract

## Outer loop: acceptance behaviors

The feature is a pure value object with no user-visible surface of its own,
so the loop runs inside-out: acceptance behaviors are exercised through the
breaker's public API (the read, the transitions, the serialization) — the
entry points the fallback-chain coordinator and the persistence layer
consume.

| id  | behavior                                                                       | traces     | kind             | state   | test                                                              |
| --- | ------------------------------------------------------------------------------ | ---------- | ---------------- | ------- | ------------------------------------------------------------------ |
| A1  | shouldProbe is false in closed (nothing to recover)                            | AC US1-1   | example          | PENDING |                                                                    |
| A2  | shouldProbe is false one tick before the cooldown boundary, true at it         | AC US1-2   | example          | PENDING |                                                                    |
| A3  | shouldProbe is false in halfOpen (probe in flight, not due)                    | AC US1-3   | example          | PENDING |                                                                    |
| A4  | A recovered breaker's next single failure stays closed on a fresh streak       | AC US2-1   | example          | PENDING |                                                                    |
| A5  | Fresh-threshold failures after recovery re-trip the breaker open               | AC US2-2   | example          | PENDING |                                                                    |
| A6  | A half-open failure re-trips open with probes reset and openedAt stamped       | AC US2-3   | example          | PENDING |                                                                    |
| A7  | Every state round-trips JSON field-exactly (closed/open/halfOpen)              | AC US3-1   | example          | PENDING |                                                                    |
| A8  | A restored open breaker continues its cooldown from the original openedAt      | AC US3-1   | example          | PENDING |                                                                    |
| A9  | Mid-probe halfOpen resumes with partial halfOpenSuccesses after round-trip     | AC US3-2   | example          | PENDING |                                                                    |

## Inner loop: unit behaviors

Grouped by the component from `plan.md` that owns them.

### `lib/src/domain/entities/circuit_breaker/circuit_breaker.dart` (shouldProbe)

| id  | behavior                                                                       | traces     | kind             | state   | test                                                              |
| --- | ------------------------------------------------------------------------------ | ---------- | ---------------- | ------- | ------------------------------------------------------------------ |
| U1  | shouldProbe is false for an open breaker with null openedAt (defensive)        | edge-1, FR-002 | example       | PENDING |                                                                  |
| U2  | shouldProbe never transitions the breaker (read-only)                          | FR-002     | example          | PENDING |                                                                    |

### `lib/src/domain/entities/circuit_breaker/circuit_breaker.dart` (persistence)

| id  | behavior                                                                       | traces     | kind             | state   | test                                                              |
| --- | ------------------------------------------------------------------------------ | ---------- | ---------------- | ------- | ------------------------------------------------------------------ |
| U3  | Malformed JSON throws ArgumentError naming the field (missing, unknown state, negative counters, thresholds < 1, cooldown <= 0, bad timestamps) | edge-3, FR-005 | example | PENDING |                          |
| U4  | openedAt/lastFailureAt serialize only when non-null (absent-never-fabricated)  | edge-4, FR-004 | example       | PENDING |                                                                    |
| U5  | Cooldown duration round-trips exactly as microseconds (no drift)               | FR-004     | example          | PENDING |                                                                    |
| U6  | The 12 pre-existing provider/compile-parity tests keep passing unchanged       | FR-001, FR-006 | BASELINE     | BASELINE | `test/data/providers/circuit_breaker/circuit_breaker_provider_test.dart` |

## Invariants and edge cases still to place

- Boundary discipline: A2 pins BOTH sides of `elapsed >= cooldown` (inclusive) with the same clock values tryHalfOpen uses — the read and the transition cannot diverge.
- Read-only discipline: U2 — shouldProbe must not be a hidden transition.
- Absent-never-fabricated serialization: U4 — the house discipline from 031-034.

## Out of scope

- Escalating backoff (cooldown doubling per re-trip): the epic's "backoff" is read as the fixed cooldown (documented edge); a future feature may extend.
- Wiring `CircuitBreakerProvider` to a real store: separate feature (FR-006 keeps the stubs).
- `lib/src/llm/circuit_breaker.dart` (the LLM-runtime breaker): separate spec family (007/008); this feature refines only the domain value object.
- Health-snapshot mapping: spec 054's territory.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md` at planning time:

- Single test: `dart test test/domain/entities/circuit_breaker/circuit_breaker_test.dart -n "<name>"` (mind regex-special characters — 033 cycle-log lesson)
- File: `dart test test/domain/entities/circuit_breaker/circuit_breaker_test.dart`
- Full suite: `dart test`
- Mutation (changed files): no tool wired — deliberate hand-mutants per the profile

## Mutation targets (deliberate-mutant sampling)

| target | mutant | killed by |
| ------ | ------ | --------- |
| boundary | shouldProbe flips to strict `>` (exclusive boundary) | A2 |
| read-only | shouldProbe transitions to halfOpen itself | U2 |
| cooldown restore | fromJson resets openedAt to the parse time | A8 |
| parse guard | fromJson defaults an unknown state string to closed | U3 |
