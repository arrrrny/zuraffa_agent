# Tasks: AgentMessage (multimodal parts) + history (validation, equality fix, truncate)

**Input**: Design documents from `/specs/041-agent_message/` (spec refined 2026-08-27, plan refined 2026-08-27)

**Prerequisites**: plan.md, spec.md

**Tests**: MANDATORY — every behavior lands test-first per `/speckit.tdd.plan`; tests must be observed failing first (red) before implementation.

**Organization**: Tasks grouped by user story; dependency-ordered (MVP-first: US1 equality fix is the correctness deliverable; US2 truncate completes the lifecycle; US3 pins).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to

## Phase 1: TDD list + baseline

- [x] T001 [US1] Derive `specs/041-agent_message/tdd/test-list.md` via `/speckit.tdd.plan` [A1] [A2] [A3] [A4] [A5] [U1]–[U10] (baseline cycle-log entry recorded post-spec-038, suite 727 green)

## Phase 2: US1 — validated entity + parts value equality (the correctness deliverable)

- [x] T002 [US1] Write failing tests: empty id / empty role throw ArgumentError [U1] — red before implementation
- [x] T003 [US1] Write failing tests: distinct-instance equal-parts messages are == and hash equally; single-field differences unequal [U2] [U3] — red before implementation
- [x] T004 [US1] Implement validation (FR-001) + element-wise parts equality + hashAll hashCode (FR-002) — smallest change that greens T002–T003
- [x] T005 [US1] Full suite green + analyze zero new findings (SC-001, SC-002) [A1] [A2] [A3]

## Phase 3: US2 — history truncate

- [x] T006 [US2] Write failing tests: truncate keeps last N, memories + summaries unchanged; 0 -> empty; negative throws; n >= length content-equal [U4] [U5] [U6] — red before implementation
- [x] T007 [US2] Implement `truncate` (FR-004) — smallest change that greens T006
- [x] T008 [US2] Full suite green (SC-003) [A4]

## Phase 4: US3 — pins

- [x] T009 [P] [US3] Pin tests: appendMessages + addMemory shipped semantics (characterization, deliberate-mutant verified) [A5] [U7] [U8]
- [x] T010 [P] [US3] Pin coverage: types_test.dart role/part dispatch, 5-test provider suite, and clean-arch stubs stay green unchanged (FR-006/007) [A5] [U9] [U10]

## Phase 5: Verification + docs

- [x] T011 Run `/speckit.tdd.verify`: mutation evidence, test-first audit, coverage -> `specs/041-agent_message/tdd/verification.md` (all behaviors DONE, verdict recorded)
- [x] T012 Commit spec-kit artifacts (spec.md, plan.md, tasks.md, tdd/*) with the code per repo convention
