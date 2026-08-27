# Tasks: UiTreePayload value object (serialization + diffing slice)

**Input**: Design documents from `/specs/038-ui-tree-payload/` (spec refined 2026-08-27, plan refined 2026-08-27)

**Prerequisites**: plan.md, spec.md

**Tests**: MANDATORY — every behavior lands test-first per `/speckit.tdd.plan`; tests must be observed failing first (red) before implementation.

**Organization**: Tasks grouped by user story; dependency-ordered (MVP-first: US1 serialization is the boundary contract; US2 diffing builds on it; US3 pins shipped behavior).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to

## Phase 1: TDD list + baseline

- [x] T001 [US1] Derive `specs/038-ui-tree-payload/tdd/test-list.md` via `/speckit.tdd.plan` [A1] [A2] [A3] [A4] [A5] [U1]–[U10] (baseline cycle-log entry recorded post-spec-037, suite 716 green)

## Phase 2: US1 — serialization round-trip

- [x] T002 [US1] Write failing tests: toJson exact four-key shape; 3-level round-trip equality [U1] — red before implementation
- [x] T003 [US1] Write failing tests: fromJson rejects missing/wrong mimeType, empty pinning fields, non-map tree [U2] — red before implementation
- [x] T004 [US1] Implement `toJson` + `fromJson` (FR-001/002) — smallest change that greens T002–T003
- [x] T005 [US1] Full suite green + analyze zero new findings (SC-001, SC-002) [A1] [A2]

## Phase 3: US2 — structural diffing

- [x] T006 [US2] Write failing tests: diff reports exact added/removed/changed path sets on a mixed fixture; root change lands in changedPaths [U3] [U4] — red before implementation
- [x] T007 [US2] Write failing tests: pinning drift flags with empty structural delta; identical payloads yield empty diff [U5] — red before implementation
- [x] T008 [US2] Implement `diff` + `UiTreeDiff` value object (FR-003/004) — smallest change that greens T006–T007
- [x] T009 [US2] Full suite green (SC-003, SC-004) [A3] [A4]

## Phase 4: US3 — pins

- [x] T010 [P] [US3] Pin coverage: 11 pre-existing payload + clean-arch tests stay green unchanged (FR-005/006) [A5] [U6] [U7] [U8]
- [x] T011 [P] [US3] Pin test: UiTreeDiff value-object semantics (equality, toString, deterministic path order) [U9] [U10]

## Phase 5: Verification + docs

- [x] T012 Run `/speckit.tdd.verify`: mutation evidence, test-first audit, coverage -> `specs/038-ui-tree-payload/tdd/verification.md` (all behaviors DONE, verdict recorded)
- [x] T013 Commit spec-kit artifacts (spec.md, plan.md, tasks.md, tdd/*) with the code per repo convention
