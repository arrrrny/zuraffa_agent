# Tasks: SubAgentSpec value object (validation + pinned semantics)

**Input**: Design documents from `/specs/036-sub-agent-spec/` (spec refined 2026-08-27, plan refined 2026-08-27)

**Prerequisites**: plan.md, spec.md

**Tests**: MANDATORY for this feature — every behavior lands test-first per `/speckit.tdd.plan`; tests must be observed failing first (red) before implementation.

**Organization**: Tasks grouped by user story; dependency-ordered (MVP-first: US1 validation is the deliverable slice; US2/US3 pin already-shipped behavior).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to

## Phase 1: TDD list + baseline

- [x] T001 [US1] Derive `specs/036-sub-agent-spec/tdd/test-list.md` from spec.md + plan.md via `/speckit.tdd.plan` [A1] [A2] [A3] [A4] [A5] [A6] [A7] [U1]–[U14] (behaviors traced to AC/FR ids; baseline cycle-log entry recorded at `7da6902`, suite 695 green)

## Phase 2: US1 — validated construction (the deliverable slice)

- [x] T002 [US1] Write failing tests: identity-field validation (empty name/description/systemPrompt throw ArgumentError) [U1] [U2] [U3] in `test/domain/entities/sub_agent_spec/sub_agent_spec_test.dart` — red before implementation
- [x] T003 [US1] Write failing tests: allowlist validation (blank tool id, blank sub-agent name throw ArgumentError) [U4] [U5] — red before implementation
- [x] T004 [US1] Write failing tests: budget validation (maxTurns 0, contextWindowTokens 0, negative wallClockTimeout throw; Duration.zero and null budgets stay valid) [U6] [U7] [U8] — red before implementation
- [x] T005 [US1] Implement construction-time validation in `lib/src/domain/entities/sub_agent_spec/sub_agent_spec.dart` (FR-001..003) [U1] [U2] [U3] [U4] [U5] [U6] [U7] [U8] — constructor becomes non-const; smallest change that greens T002–T004
- [x] T006 [US1] Full suite green + `dart analyze` zero new findings (SC-001, SC-003, SC-004) [A1] [A2] [A3] [A6] [A7] [U14]

## Phase 3: US2 — inheritance constraint

- [x] T007 [US2] Write failing tests: self-extends (extendsSpec == name) throws ArgumentError; valid parent reference constructs [U9] — red before implementation
- [x] T008 [US2] Implement the 1-cycle check (FR-004) [U9] — smallest change that greens T007

## Phase 4: US3 — pin shipped semantics (characterization)

- [x] T009 [P] [US3] Pin tests: structural getters across the four canonical shapes (isLeaf/isRoot/hasBudgets) [A5] [U10] [U11] — expected green against shipped code (characterization, deliberate-mutant verified)
- [x] T010 [P] [US3] Pin tests: value equality/hashCode across all ten fields with independently constructed lists (FR-006) [A6] [U12]
- [x] T011 [P] [US3] Pin tests: clean-arch layers unchanged (11 pre-existing provider/entity tests stay green — FR-007, SC-003) [A7] [U13] [U14]

## Phase 5: Verification + docs

- [x] T012 Run `/speckit.tdd.verify`: mutation evidence (hand-mutants), test-first audit, acceptance-criteria coverage -> `specs/036-sub-agent-spec/tdd/verification.md` (all behaviors DONE, verdict recorded)
- [x] T013 Commit spec-kit artifacts (spec.md, plan.md, tasks.md, tdd/*) with the code per repo convention
