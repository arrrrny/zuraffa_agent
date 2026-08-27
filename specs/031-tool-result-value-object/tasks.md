# Tasks: ToolResult value object + clean-arch layers

**Input**: Design documents from `specs/031-tool-result-value-object/` (spec.md, plan.md)

**Prerequisites**: plan.md (required), spec.md (required)

**Tests**: Mandatory — driven test-first (tdd/test-list.md); red evidence in tdd/cycle-log.md.

**Organization**: Grouped by user story; dependency-ordered, MVP-first (US1 success/error + serialization is the MVP slice).

## Phase 1: isError + equality/hashCode contract fix (US3 + US1 core)

- [ ] T001 [US3] RED→GREEN: `test/domain/entities/tool_result/tool_result_test.dart` — equal results with distinct-but-equal payload map instances share hashCode (the scaffold's live contract violation — genuinely red today); order-independent payload hashing; unequal across content / payload / isError / artifactRef axes (FR-001, FR-002, FR-006, AC US3-1..2, SC-004, SC-005)
- [ ] T002 [US1] RED→GREEN: `success`/`error` factories set isError false/true; isError participates in equality; default construction stays isError=false (backward compat) (FR-001, FR-002)
- [ ] T003 [US1] Implement: enrich `lib/src/domain/entities/tool_result/tool_result.dart` — isError field, factories, order-independent hashCode fold, equality extension

## Phase 2: Serialization (US1)

- [ ] T004 [US1] RED→GREEN: toJson/fromJson round-trips — success with payload, error without payload (payload key absent, not empty map), isError preserved, artifactRef nested {kind,id,uri} round-trip, inline results omit artifactRef (FR-003, FR-005, AC US1-1..3, SC-001, SC-003)
- [ ] T005 [US1] Implement: toJson/fromJson on the value object

## Phase 3: Oversized path (US2)

- [ ] T006 [US2] RED→GREEN: `ToolResult.oversized` — requires summary + artifactRef, isSummarized true, round-trips with the ref, inline results are isSummarized false; oversized error allowed (FR-004, FR-005, AC US2-1..3, SC-002)
- [ ] T007 [US2] Implement: the oversized named constructor

## Phase 4: Verification + docs

- [ ] T008 Verify the 7 pre-existing provider/compile-parity tests still pass unchanged (FR-007 — layers untouched)
- [ ] T009 Run `dart analyze` (zero new issues vs 5-issue baseline) + full `dart test` (green; post-29 baseline 562)
- [ ] T010 [P] Commit spec-kit artifacts (spec/plan/tasks/tdd/*) with the code, Conventional Commits
- [ ] T011 `/speckit.tdd.verify` — write `tdd/verification.md` with verdict + deliberate-mutant evidence

## Dependency Graph

```text
T001 ─▶ T002 ─▶ T003 ─▶ T004 ─▶ T005 ─▶ T006 ─▶ T007 ─▶ T008 ─▶ T009 ─▶ T010 ─▶ T011
```

## Cross-artifact consistency (analyze step)

FR-001/002/006 ↦ T001..T003; FR-003/005 ↦ T004/T005; FR-004 ↦ T006/T007; FR-007 ↦ T008.
SC-001 ↦ T004; SC-002 ↦ T006; SC-003 ↦ T004; SC-004/005 ↦ T001; SC-006 ↦ T009.
All 8 ACs ↦ tasked (US1-1..3 → T004, US2-1..3 → T004/T006, US3-1..2 → T001). Plan phases ↔ task phases aligned. No residual drift.
