# Tasks: AgentTool entity + RiskTier enum — classification, registry persistence, hash contract

**Input**: Design documents from `specs/034-agent-tool-risk-tier/` (spec.md, plan.md)

**Prerequisites**: plan.md (required), spec.md (required)

**Tests**: Mandatory — driven test-first (tdd/test-list.md); red evidence in tdd/cycle-log.md.

**Organization**: Grouped by user story; dependency-ordered, MVP-first (US3 hash contract fix is the MVP slice — it is the LIVE violation, verified by probe).

## Phase 1: Hash contract fix (US3)

- [ ] T001 [US3] RED→GREEN: `test/domain/entities/agent_tool/agent_tool_test.dart` — equal tools with distinct-but-equal paramsSchema instances share hashCode (the scaffold's LIVE contract violation, verified by probe); order-independent hashing across insertion orders; per-axis inequality still holds (FR-001, FR-006, AC US3-1..3, SC-005, SC-006)
- [ ] T002 [US3] Implement: recursive order-independent hash fold on `lib/src/domain/entities/agent_tool/agent_tool.dart` (`_foldHash`: commutative sum over map entries, order-sensitive list fold) — equality untouched

## Phase 2: Tier/mode classification parsing (US1)

- [ ] T003 [US1] RED→GREEN: `RiskTier.fromString` parses safe/confirm/admin exactly and round-trips via name; unknown strings (incl. case mismatches) throw ArgumentError naming the input; `ExecutionMode.fromString` parses sequential/parallel with the same discipline (FR-002, FR-003, AC US1-1..2, SC-001)
- [ ] T004 [US1] Implement: `fromString` on both enums

## Phase 3: Registry persistence contract (US2)

- [ ] T005 [US2] RED→GREEN: `toJson`/`fromJson` round-trips a fully-declared tool (tier + mode as names, deep schema); schema-less tool serializes paramsSchema absent; malformed JSON (missing keys, unknown tier/mode, non-map schema) throws ArgumentError naming the field (FR-004, AC US2-1..3, SC-002, SC-003, SC-004)
- [ ] T006 [US2] Implement: `toJson`/`fromJson` on the declaration value object (tier/mode routed through fromString — single source of truth)

## Phase 4: Verification + docs

- [ ] T007 Verify the 10 pre-existing provider/compile-parity tests still pass unchanged (FR-001, FR-005, FR-007 — layers untouched)
- [ ] T008 Run `dart analyze --fatal-infos` (zero findings) + full `dart test` (green; post-033 baseline 626 + new)
- [ ] T009 [P] Commit spec-kit artifacts (spec/plan/tasks/tdd/*) with the code, Conventional Commits
- [ ] T010 `/speckit.tdd.verify` — write `tdd/verification.md` with verdict + deliberate-mutant evidence

## Dependency Graph

```text
T001 ─▶ T002 ─▶ T003 ─▶ T004 ─▶ T005 ─▶ T006 ─▶ T007 ─▶ T008 ─▶ T009 ─▶ T010
```

## Cross-artifact consistency (analyze step)

FR-001 ↦ T001 (inequality axes) + T007; FR-002 ↦ T003/T004; FR-003 ↦ T003/T004; FR-004 ↦ T005/T006; FR-005 ↦ T007; FR-006 ↦ T001/T002; FR-007 ↦ T007.
SC-001 ↦ T003; SC-002/003/004 ↦ T005; SC-005 ↦ T001; SC-006 ↦ T001; SC-007 ↦ T008.
All 9 ACs ↦ tasked (US1-1..3 → T003, US2-1..3 → T005, US3-1..3 → T001). Plan phases ↔ task phases aligned. The stale net-new note in the task input is resolved in spec.md's refinement note (repo spec.md governs; datasource-pair layering out of scope with reason). No residual drift.
