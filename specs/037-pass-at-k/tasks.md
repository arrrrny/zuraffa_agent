# Tasks: PassAtK unbiased estimator (eval-run + threshold slice)

**Input**: Design documents from `/specs/037-pass-at-k/` (spec refined 2026-08-27, plan refined 2026-08-27)

**Prerequisites**: plan.md, spec.md

**Tests**: MANDATORY — every behavior lands test-first per `/speckit.tdd.plan`; tests must be observed failing first (red) before implementation.

**Organization**: Tasks grouped by user story; dependency-ordered (MVP-first: US1 fromResults is the harness entry point).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to

## Phase 1: TDD list + baseline

- [x] T001 [US1] Derive `specs/037-pass-at-k/tdd/test-list.md` via `/speckit.tdd.plan` [A1] [A2] [A3] [A4] [A5] [U1]–[U8] (baseline cycle-log entry recorded post-spec-036, suite 709 green)

## Phase 2: US1 — fromResults (the harness entry point)

- [x] T002 [US1] Write failing tests: fromResults over a 10-outcome run equals compute on the derived triple [U1] — red before implementation
- [x] T003 [US1] Write failing tests: fromResults throws on empty outcomes / k < 1 / k > n; order-independence with shuffled fixtures [U2] — red before implementation
- [x] T004 [US1] Implement `fromResults` (FR-001) — smallest change that greens T002–T003
- [x] T005 [US1] Full suite green + analyze zero new findings (SC-001, SC-002) [A1] [A2]

## Phase 3: US2 — threshold decisions

- [x] T006 [US2] Write failing tests: meetsThreshold inclusive at boundary, both sides flip, range + NaN errors [U3] [U4] — red before implementation
- [x] T007 [US2] Implement `meetsThreshold` (FR-002) — smallest change that greens T006
- [x] T008 [US2] Full suite green (SC-003) [A3]

## Phase 4: US3 — invariants + pins

- [x] T009 [US3] Pin test: k-sweep monotonicity 1..n-c (characterization, deliberate-mutant verified) [A4] [U5]
- [x] T010 [P] [US3] Pin coverage: 13 pre-existing metric + clean-arch tests stay green unchanged (FR-004/005) [A5] [U6] [U7] [U8]

## Phase 5: Verification + docs

- [x] T011 Run `/speckit.tdd.verify`: mutation evidence, test-first audit, coverage -> `specs/037-pass-at-k/tdd/verification.md` (all behaviors DONE, verdict recorded)
- [x] T012 Commit spec-kit artifacts (spec.md, plan.md, tasks.md, tdd/*) with the code per repo convention
