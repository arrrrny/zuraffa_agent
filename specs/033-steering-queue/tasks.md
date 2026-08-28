# Tasks: SteeringQueue + SteeringMessage — enqueue/dispatch/inject semantics

**Input**: Design documents from `specs/033-steering-queue/` (spec.md, plan.md)

**Prerequisites**: plan.md (required), spec.md (required)

**Tests**: Mandatory — driven test-first (tdd/test-list.md); red evidence in tdd/cycle-log.md.

**Organization**: Grouped by user story; dependency-ordered, MVP-first (US1 enqueue is the MVP slice — the write side of the R1.3 contract).

## Phase 1: Defensive immutability + enqueue (US1)

- [ ] T001 [US1] RED→GREEN: `test/domain/entities/steering_queue/steering_queue_test.dart` — enqueue appends FIFO + stamps lastInjectedAt + leaves the source unchanged; mutating the constructor's source list does not affect the queue; direct writes to `queue.pending` throw (FR-001, FR-002, AC US1-1..3, SC-001, SC-006)
- [ ] T002 [US1] Implement: defensive copy in the `SteeringQueue` constructor (`List.unmodifiable`) + the `enqueue` pure transition

## Phase 2: Pop dispatch transition (US2)

- [ ] T003 [US2] RED→GREEN: `pop` returns `({message, queue})` with head out, processedCount + 1, lastInjectedAt preserved; double-pop drains FIFO; empty pop throws `StateError` naming the queue id (FR-003, AC US2-1..3, SC-002, SC-003)
- [ ] T004 [US2] Implement: the `pop` transition returning the Dart 3 record

## Phase 3: Persistence contract (US3)

- [ ] T005 [US3] RED→GREEN: `SteeringMessage.toJson/fromJson` round-trip; `SteeringQueue.toJson/fromJson` round-trips populated queues incl. FIFO order + processedCount; empty queue omits lastInjectedAt and restores null; malformed JSON (missing keys, non-list pending, non-map entries) throws ArgumentError (FR-004, AC US3-1..3, SC-004, SC-005)
- [ ] T006 [US3] Implement: `toJson`/`fromJson` on both value objects

## Phase 4: Verification + docs

- [ ] T007 Verify the 9 pre-existing provider/compile-parity tests still pass unchanged (FR-005, FR-006 — layers untouched)
- [ ] T008 Run `dart analyze --fatal-infos` (zero findings) + full `dart test` (green; post-032 baseline 611 + new)
- [ ] T009 [P] Commit spec-kit artifacts (spec/plan/tasks/tdd/*) with the code, Conventional Commits
- [ ] T010 `/speckit.tdd.verify` — write `tdd/verification.md` with verdict + deliberate-mutant evidence

## Dependency Graph

```text
T001 ─▶ T002 ─▶ T003 ─▶ T004 ─▶ T005 ─▶ T006 ─▶ T007 ─▶ T008 ─▶ T009 ─▶ T010
```

## Cross-artifact consistency (analyze step)

FR-001 ↦ T001/T002 (defensive copy assertions); FR-002 ↦ T001/T002; FR-003 ↦ T003/T004; FR-004 ↦ T005/T006; FR-005 ↦ T001 (existing getters/equality keep passing) + T007; FR-006 ↦ T007.
SC-001 ↦ T001; SC-002/003 ↦ T003; SC-004/005 ↦ T005; SC-006 ↦ T001; SC-007 ↦ T008.
All 9 ACs ↦ tasked (US1-1..3 → T001, US2-1..3 → T003, US3-1..3 → T005). Plan phases ↔ task phases aligned. No residual drift.
