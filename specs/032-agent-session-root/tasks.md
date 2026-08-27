# Tasks: AgentSession root entity — aggregate transitions + persistence contract

**Input**: Design documents from `specs/032-agent-session-root/` (spec.md, plan.md)

**Prerequisites**: plan.md (required), spec.md (required)

**Tests**: Mandatory — driven test-first (tdd/test-list.md); red evidence in tdd/cycle-log.md.

**Organization**: Grouped by user story; dependency-ordered, MVP-first (US1 cursor advance is the MVP slice — the most frequent engine write).

## Phase 1: Cursor transition (US1)

- [ ] T001 [US1] RED→GREEN: `test/domain/entities/agent_session/agent_session_test.dart` — `appendEntry` advances the cursor + stamps `updatedAt` + leaves the source unchanged + rejects empty entry ids with `ArgumentError`; first append moves the cursor off null (FR-002, FR-006, AC US1-1..3, SC-001)
- [ ] T002 [US1] Implement: `appendEntry` on `lib/src/domain/entities/agent_session/agent_session.dart` — pure snapshot transition with injected clock

## Phase 2: Branch transition (US2)

- [ ] T003 [US2] RED→GREEN: `fork` produces a child linked via `parentSessionId` at the current head; fresh-session fork falls back to the root anchor; missionId inherited; source unchanged (FR-003, FR-006, AC US2-1..3, SC-002)
- [ ] T004 [US2] Implement: `fork` named-parameter transition on the root entity

## Phase 3: Persistence contract (US3)

- [ ] T005 [US3] RED→GREEN: `toJson`/`fromJson` round-trips a fully-populated session field-exactly; minimal session omits null optionals and restores them null; malformed JSON (missing/ill-typed required keys) throws `ArgumentError` naming the key (FR-004, AC US3-1..3, SC-003, SC-004, SC-005)
- [ ] T006 [US3] Implement: `toJson`/`fromJson` on the root entity

## Phase 4: Verification + docs

- [ ] T007 Verify the 8 pre-existing provider/compile-parity tests still pass unchanged (FR-001, FR-005 — layers untouched)
- [ ] T008 Run `dart analyze --fatal-infos` (zero findings) + full `dart test` (green; baseline 597 + new)
- [ ] T009 [P] Commit spec-kit artifacts (spec/plan/tasks/tdd/*) with the code, Conventional Commits
- [ ] T010 `/speckit.tdd.verify` — write `tdd/verification.md` with verdict + deliberate-mutant evidence

## Dependency Graph

```text
T001 ─▶ T002 ─▶ T003 ─▶ T004 ─▶ T005 ─▶ T006 ─▶ T007 ─▶ T008 ─▶ T009 ─▶ T010
```

## Cross-artifact consistency (analyze step)

FR-001 ↦ T007; FR-002 ↦ T001/T002; FR-003 ↦ T003/T004; FR-004 ↦ T005/T006; FR-005 ↦ T007; FR-006 ↦ T001/T003 (immutability assertions inside both).
SC-001 ↦ T001; SC-002 ↦ T003; SC-003/004/005 ↦ T005; SC-006 ↦ T008.
All 9 ACs ↦ tasked (US1-1..3 → T001, US2-1..3 → T003, US3-1..3 → T005). Plan phases ↔ task phases aligned (Phase 1=US1, Phase 2=US2, Phase 3=US3, Phase 4=gates). No residual drift.
