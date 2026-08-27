# Tasks: ToolCallSignature datasource + mock pair

**Input**: Design documents from `specs/29-tool_call_signature-datasource-pair/` (spec.md, plan.md)

**Prerequisites**: plan.md (required), spec.md (required)

**Tests**: Mandatory — driven test-first (tdd/test-list.md); red evidence in tdd/cycle-log.md.

**Organization**: Grouped by user story; dependency-ordered, MVP-first (US1 capture/lookup is the MVP slice).

## Phase 1: Entity — content-addressable identity (blocking prerequisite)

- [ ] T001 [US2] RED→GREEN: `test/domain/entities/tool_call_signature/tool_call_signature_test.dart` — equal content ⇒ equal + same hashCode + identical key; any differing component (toolName / argumentHash / version) ⇒ unequal + different key; key format `toolName@version:argumentHash`; version defaults to 1; legacy `ToolCallSignature(id: ...)` construction compiles; equality ignores a legacy explicit id (content triple decides) (FR-001, FR-002, FR-003, SC-003)
- [ ] T002 [US2] Implement: enrich `lib/src/domain/entities/tool_call_signature/tool_call_signature.dart` — content fields, derived const key, content equality/hashCode/toString

## Phase 2: Interface + mock — capture/lookup (US1 MVP)

- [ ] T003 [US1] RED→GREEN: `test/data/datasources/tool_call_signature/tool_call_signature_mock_datasource_test.dart` — capture→lookup round-trip returns the equal signature; unknown-key lookup returns null (no throw); compile parity `isA<ToolCallSignatureDatasource>()` kept (FR-004, FR-006, AC US1-1..2, SC-001, SC-002)
- [ ] T004 [US1] Implement: interface `capture`/`lookup`/`count`/`reset` (documented drop of scaffolded `current()`); mock as key-addressed `Map<String, ToolCallSignature>`

## Phase 3: Idempotency + bounded store (US2-3 + US3)

- [ ] T005 [US2] RED→GREEN: duplicate capture tests — capturing equal content twice keeps `count` at 1 (FR-005, AC US2-3, edge-1, SC-004)
- [ ] T006 [US2] Implement (if red reveals gaps): idempotent capture semantics in the mock
- [ ] T007 [US3] RED→GREEN: count/reset tests — `count` reflects distinct captures; `reset()` zeroes count and clears lookups (FR-007, AC US3-1..2, SC-005)
- [ ] T008 [US3] Implement (if red reveals gaps): reset semantics in the mock

## Phase 4: Verification + docs

- [ ] T009 Run `dart analyze` (zero new issues vs 5-issue baseline) + full `dart test` (green; post-27 baseline 551)
- [ ] T010 [P] Commit spec-kit artifacts (spec/plan/tasks/tdd/*) with the code, Conventional Commits
- [ ] T011 `/speckit.tdd.verify` — write `tdd/verification.md` with verdict + deliberate-mutant evidence

## Dependency Graph

```text
T001 ─▶ T002 ─▶ T003 ─▶ T004 ─▶ T005 ─▶ T006 ─▶ T007 ─▶ T008 ─▶ T009 ─▶ T010 ─▶ T011
```

## Cross-artifact consistency (analyze step)

FR-001..003 ↦ T001/T002; FR-004/006 ↦ T003/T004; FR-005 ↦ T005/T006; FR-007 ↦ T007/T008.
SC-001..002 ↦ T003; SC-003 ↦ T001; SC-004 ↦ T005; SC-005 ↦ T007; SC-006 ↦ T009.
All 7 ACs ↦ tasked (US1-1..2 → T003, US2-1..3 → T001/T005, US3-1..2 → T007). Plan phases ↔ task phases aligned. No orphan tasks, no untasked requirements. No residual drift.
