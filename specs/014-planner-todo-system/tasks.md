# Tasks: Planner/TODO System
- [x] T1 Write the planner test suite first (TDD red): `test/data/providers/planner/planner_provider_test.dart` — StepStatus enum, PlanStep transitions, PlanState SC-001 progress accuracy + SC-003 five-turn persistence, PlanMode FR-003 semantics, Planner/WriteTodosTool FR-001 injectability + SC-002, PlanChangedEvent FR-005, clean-arch layer wiring.
- [x] [U1] StepStatus has pending/inProgress/completed/cancelled + isTerminal — `planner_provider_test.dart::StepStatus`
- [x] [U2] PlanStep defaults to pending; copyWith is pure; value equality — `planner_provider_test.dart::PlanStep`
- [x] [U3] PlanState reports accurate counts + progressFraction (SC-001) — `planner_provider_test.dart::PlanState — SC-001 accurate progress`
- [x] [U4] PlanMode none/auto/must injection + planning semantics (FR-003) — `planner_provider_test.dart::PlanMode — FR-003 configuration`
- [x] [U5] PlanChangedEvent carries previous/next/emittedAt + completedGained (FR-005) — `planner_provider_test.dart::PlanChangedEvent — FR-005`
- [x] [U6] WriteTodosTool is an AgentTool declaration; Planner injects per mode; must forces planning (FR-001/SC-002) — `planner_provider_test.dart::Planner + WriteTodosTool — FR-001 injectable tool`
- [x] [U7] PlanState persists across 5 turns via immutable snapshots (SC-003) — `planner_provider_test.dart::PlanState — SC-003 persists across turns`
- [x] [U8] Clean-arch layers wired: PlannerProvider is a PlannerService stub; type bounds usable — `planner_provider_test.dart::Clean-architecture layers`
- [x] T2 Create `lib/src/domain/entities/planner/step_status.dart` (enum: pending, inProgress, completed, cancelled).
- [x] T3 Create `lib/src/domain/entities/planner/plan_step.dart` (value object + copyWith + equality).
- [x] T4 Create `lib/src/domain/entities/planner/plan_state.dart` (immutable snapshot + count/progress getters + pure update methods).
- [x] T5 Create `lib/src/domain/entities/planner/plan_mode.dart` (enum: none, auto, must + injection/planning semantics).
- [x] T6 Create `lib/src/domain/entities/planner/plan_changed_event.dart` (previous/next/emittedAt).
- [x] T7 Create `lib/src/domain/entities/planner/write_todos_tool.dart` (canonical AgentTool declaration + params schema).
- [x] T8 Create `lib/src/domain/entities/planner/planner.dart` (Planner value object exposing the tool per mode).
- [x] T9 Create `lib/src/domain/repositories/plan_state_repository.dart` (abstract).
- [x] T10 Create `lib/src/domain/services/planner_service.dart` (abstract, NoParams parameterless methods).
- [x] T11 Create `lib/src/data/providers/planner/planner_provider.dart` (concrete stub).
- [x] T12 Upload plan.md/tasks.md alongside spec.md.
- [x] T13 `dart pub get && dart analyze --fatal-infos && dart test` all green (baseline 379 + new planner tests).
- [x] T14 Commit + push + PR to master (repair commits for PR #58 breakage ride along on this branch).

## Phase 3: TDD remediation

Source: `tdd/verification.md` @ `01618f3` — **verdict FAIL**. This feature is **not
done** until T15–T18 below are cleared; T15 comes first because it is a false
claim in this very file. HIGH findings only; MED/LOW findings 5–9 are recorded in
the report and not tracked here.

- [ ] T15 (finding #1, HIGH) Resolve the false test-first claim at `specs/014-planner-todo-system/tasks.md:2`: `T1 Write the planner test suite first (TDD red)` is ticked, but `tdd/cycle-log.md` records no cycle and `0f0145e` shipped all 10 source files with the 376-line test file in one commit. Untick T1 and restate it as "record the planner suite as test-after", matching `tdd/test-list.md:14-16`. Prove it done: `git log --oneline -- test/data/providers/planner/planner_provider_test.dart lib/src/domain/entities/planner/` and `tdd/cycle-log.md` agree with the wording in `tasks.md`.
- [ ] T16 (finding #2, HIGH) Remove or replace the assertion-free test at `test/data/providers/planner/planner_provider_test.dart:370-374` (`'PlanStateRepository is usable as a type bound'`, which asserts `expect(true, isTrue)`): either delete it — `dart analyze --fatal-infos` already enforces the type bound — or replace it with an in-test fake `PlanStateRepository` whose `update`/`getCurrent`/`reset` are asserted to round-trip a `PlanState` snapshot. Prove it done: `dart test test/data/providers/planner/planner_provider_test.dart` is green and no test in the file asserts a constant.
- [ ] T17 (finding #4, HIGH) Give US1-AC1 and US2-AC2 tests that exercise their stated triggers, or move them out of this spec's scope in writing. Today `spec.md:23` ("model calls `write_todos` → plan state updated") is covered only by asserting the `AgentTool` declaration (`planner_provider_test.dart:248-257`), and `spec.md:37` ("planMode=must → planning required before execution") only by the enum getter (`:243`, `:288`) with no consumer anywhere in `lib/`. Prove it done: each of the two criteria names a test that drives a real caller, or `spec.md` records the criterion as deferred to the owning spec with its id.
- [ ] T18 (finding #3, HIGH) Bring the mutation evidence up to the six behaviors this audit did not sample (U1, U2, U4, U5, U6, U8), since the `TEST_AFTER` classification of all eight behaviors means deliberate mutants are the only strength evidence available. Prove it done: `tdd/verification.md` records one applied-and-caught mutant per behavior, with the file, the mutated line, and the failing expectation, and `dart test` is green after every restore.
