# Tasks: StopPolicy datasource + mock pair

**Input**: Design documents from `specs/27-stop_policy-datasource-pair/` (spec.md, plan.md)

**Prerequisites**: plan.md (required), spec.md (required)

**Tests**: Mandatory — every behavioral task driven test-first (tdd/test-list.md); red evidence in tdd/cycle-log.md.

**Organization**: Grouped by user story; dependency-ordered, MVP-first (US1 read chain is the MVP slice).

## Phase 1: Entity default constant (blocking prerequisite)

- [ ] T001 [US1] RED→GREEN: `test/domain/entities/stop_policy/stop_policy_test.dart` — `StopPolicy.defaultPolicy` exists with the documented values (100 / Duration.zero / 5 / true / 'default'); value equality across all five fields; hashCode parity (FR-001)
- [ ] T002 [US1] Implement: add `static const StopPolicy defaultPolicy` to `lib/src/domain/entities/stop_policy/stop_policy.dart`

## Phase 2: Datasource pair (US1 read + US2 update/reset)

- [ ] T003 [US1] RED→GREEN: `test/data/datasources/stop_policy/stop_policy_mock_datasource_test.dart` — fresh mock `current()` returns the default; compile parity `isA<StopPolicyDatasource>()` kept (FR-002, FR-003, AC US1-1)
- [ ] T004 [US1] Implement: extend interface with `update(StopPolicy)`; implement mock in memory seeded with `StopPolicy.defaultPolicy`
- [ ] T005 [US2] RED→GREEN: update/reset tests — `update(p)` then `current()` returns `p`; `reset()` restores the default (FR-003, AC US2-1..2, SC-001, SC-002)
- [ ] T006 [US2] Implement: full-replace update + restore-default reset in the mock

## Phase 3: Repository over the datasource (US3 seam)

- [ ] T007 [US3] RED→GREEN: `test/data/repositories/stop_policy_repository_impl_test.dart` — `getCurrent(id)` delegates (returns the seeded policy for the matching id); `update` delegates; `reset(id)` delegates; unknown id raises `StateError`; id-mismatched update makes the old id unreachable (FR-004, AC US3-2, edge-1/2, SC-004)
- [ ] T008 [US3] Implement: `lib/src/data/repositories/stop_policy_repository_impl.dart` delegating to `StopPolicyDatasource`

## Phase 4: Provider consumes the repository (US1 + US3 wiring)

- [ ] T009 [US1] RED→GREEN: `test/data/providers/stop_policy/stop_policy_provider_test.dart` — `StopPolicyProvider()` is a `StopPolicyService` (compile parity kept); `current(NoParams())` returns the default through the default wiring; `defaultPolicy(NoParams())` returns the canonical constant; injected repository over a seeded datasource is served through `current` (FR-005, FR-006, AC US1-2, US3-1, SC-003)
- [ ] T010 [US1] Implement: rewrite `lib/src/data/providers/stop_policy/stop_policy_provider.dart` — constructor-injected repository with default `StopPolicyRepositoryImpl(StopPolicyMockDatasource())` wiring

## Phase 5: Verification + docs

- [ ] T011 Run `dart analyze` (zero new issues vs 5-issue baseline) + full `dart test` (green; post-25 baseline 544)
- [ ] T012 [P] Commit spec-kit artifacts (spec/plan/tasks/tdd/*) with the code, Conventional Commits
- [ ] T013 `/speckit.tdd.verify` — write `tdd/verification.md` with verdict + deliberate-mutant evidence

## Dependency Graph

```text
T001 ─▶ T002 ─▶ T003 ─▶ T004 ─▶ T005 ─▶ T006 ─▶ T007 ─▶ T008 ─▶ T009 ─▶ T010
                                                                │
                                    T011 ─▶ T012 ─▶ T013 ◀──────┘
```
