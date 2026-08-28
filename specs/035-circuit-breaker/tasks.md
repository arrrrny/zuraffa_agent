# Tasks: CircuitBreaker state machine — recovery readiness + persistence contract

**Input**: Design documents from `specs/035-circuit-breaker/` (spec.md, plan.md)

**Prerequisites**: plan.md (required), spec.md (required)

**Tests**: Mandatory — driven test-first (tdd/test-list.md); red evidence in tdd/cycle-log.md.

**Organization**: Grouped by user story; dependency-ordered, MVP-first (US1 shouldProbe is the MVP slice — the coordinator's missing read).

## Phase 1: Recovery-readiness read (US1)

- [ ] T001 [US1] RED→GREEN: `test/domain/entities/circuit_breaker/circuit_breaker_test.dart` — shouldProbe false in closed/halfOpen; false one tick before the cooldown boundary, true at the boundary (inclusive); false for open-with-null-openedAt (defensive); shouldProbe never transitions the breaker (FR-002, AC US1-1..3, SC-001)
- [ ] T002 [US1] Implement: `shouldProbe(DateTime now)` on `lib/src/domain/entities/circuit_breaker/circuit_breaker.dart` (pure read, inclusive boundary, null-openedAt guard)

## Phase 2: Full-cycle recovery regression (US2)

- [ ] T003 [US2] Characterization (green-on-scaffold by design, documented): trip → cooldown → halfOpen → threshold successes → closed with failureCount 0; post-recovery single failure stays closed with failureCount 1 (fresh streak); fresh-threshold failures re-trip; half-open failure re-trips open with halfOpenSuccesses 0 and openedAt stamped (FR-003, AC US2-1..3, SC-002)

## Phase 3: Persistence contract (US3)

- [ ] T004 [US3] RED→GREEN: toJson/fromJson round-trip every state (closed with counters, open with timestamps, mid-probe halfOpen); restored open breaker continues its cooldown (shouldProbe agrees before/after); mid-probe resumes with partial halfOpenSuccesses; malformed JSON (missing/ill-typed fields, unknown state, negative counters, thresholds < 1, cooldown <= 0, unparseable timestamps) throws ArgumentError naming the field (FR-004, FR-005, AC US3-1..3, SC-003, SC-004, SC-005)
- [ ] T005 [US3] Implement: toJson/fromJson on the breaker (state as name, Duration as microseconds, absent-never-fabricated timestamps, parse-time threshold validation)

## Phase 4: Verification + docs

- [ ] T006 Verify the 12 pre-existing provider/compile-parity tests still pass unchanged (FR-001, FR-006 — transitions and layers untouched)
- [ ] T007 Run `dart analyze --fatal-infos` (zero findings) + full `dart test` (green; post-034 baseline 640 + new)
- [ ] T008 [P] Commit spec-kit artifacts (spec/plan/tasks/tdd/*) with the code, Conventional Commits
- [ ] T009 `/speckit.tdd.verify` — write `tdd/verification.md` with verdict + deliberate-mutant evidence

## Dependency Graph

```text
T001 ─▶ T002 ─▶ T003 ─▶ T004 ─▶ T005 ─▶ T006 ─▶ T007 ─▶ T008 ─▶ T009
```

## Cross-artifact consistency (analyze step)

FR-001 ↦ T006 (+ T003 pins the transitions); FR-002 ↦ T001/T002; FR-003 ↦ T003; FR-004 ↦ T004/T005; FR-005 ↦ T004/T005; FR-006 ↦ T006.
SC-001 ↦ T001; SC-002 ↦ T003; SC-003/004/005 ↦ T004; SC-006 ↦ T007.
All 9 ACs ↦ tasked (US1-1..3 → T001, US2-1..3 → T003, US3-1..3 → T004). Plan phases ↔ task phases aligned; the characterization phase's green-on-scaffold status is documented in plan + spec Assumptions (no false red claimed). No residual drift.
