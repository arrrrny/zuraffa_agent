---
feature: 014-planner-todo-system
loop: inside-out # value objects + clean-arch layers; no HTTP/CLI/user-visible entry point
profile: .specify/memory/tdd-profile.md
spec_criteria: 5 # US1:2 (AC1-2), US2:2 (AC1-2), US3:1 (AC1)
planned_at: fce207d
updated_at: fce207d
suite_baseline: green # 909 passed, 2 skipped
---

# Test List: Planner/TODO System (spec 014)

> Derived from `spec.md` (US1–US3 acceptance scenarios, FR-001–FR-005, SC-001–SC-003)
> and `plan.md` on `master` @ `fce207d`. The feature is already implemented and merged;
> this is a **test-after** plan recording the existing passing tests as `DONE` behaviors.
> No `RED` cycles were driven because the implementation preceded the list.

## Outer loop: acceptance behaviors

None. `loop: inside-out` — the planner ships as value objects plus clean-arch
layers (repository / service / provider) with no HTTP/CLI/user-visible entry point.
The 5 acceptance scenarios are realized by the inner-loop unit behaviors below
(traced to their AC ids).

## Inner loop: unit behaviors

### `lib/src/domain/entities/planner/*` (value objects)

| id  | behavior                                                                                              | traces     | kind    | state | test                                                                                                                       |
| --- | ----------------------------------------------------------------------------------------------------- | ---------- | ------- | ----- | -------------------------------------------------------------------------------------------------------------------------- |
| U1  | `StepStatus` has exactly `pending`/`inProgress`/`completed`/`cancelled`; `isTerminal` is true only for `completed`+`cancelled` | US1-AC1, FR-002 | example | DONE  | `test/data/providers/planner/planner_provider_test.dart::StepStatus / has pending / inProgress / completed / cancelled`     |
| U2  | `PlanStep` defaults to `pending`; `copyWith` returns a NEW step (original untouched); value equality across id/description/status | US1-AC1, FR-002 | example | DONE  | `test/data/providers/planner/planner_provider_test.dart::PlanStep / defaults to pending status`                             |
| U3  | `PlanState` reports accurate counts — `totalSteps`, `pendingCount`, `inProgressCount`, `completedCount`, `cancelledCount`, `progressFraction` (completed/total, 0.0 when empty), `isComplete` | US1-AC2, SC-001 | example | DONE  | `test/data/providers/planner/planner_provider_test.dart::PlanState — SC-001 accurate progress / 3 todos with 2 completed reflect accurate counts` |
| U4  | `PlanMode` `none`/`auto`/`must`: `none` injects no tools and requires no planning; `auto` injects optional tools; `must` injects tools and requires planning | US2-AC1, US2-AC2, FR-003 | example | DONE  | `test/data/providers/planner/planner_provider_test.dart::PlanMode — FR-003 configuration / must force planning before execution` |
| U5  | `PlanChangedEvent` carries `previous`/`next`/`emittedAt` and computes `completedGained`; value equality | FR-005     | example | DONE  | `test/data/providers/planner/planner_provider_test.dart::PlanChangedEvent — FR-005 / carries previous, next, and emittedAt` |
| U6  | `WriteTodosTool` is a canonical `AgentTool` declaration (`write_todos`, `RiskTier.safe`, sequential, required `todos`); `Planner` exposes it per mode; `toolsForInjection` returns `[writeTodosTool]` for `auto`/`must`, empty for `none`; mode=`must` forces planning before execution | US2-AC1, US2-AC2, FR-001, SC-002 | example | DONE  | `test/data/providers/planner/planner_provider_test.dart::Planner + WriteTodosTool — FR-001 injectable tool / write_todos is an AgentTool declaration with a todos schema` |
| U7  | `PlanState` persists across turns via immutable snapshots (`withSteps`/`updateStep`/`markStep` return new instances); plan state preserved after 5 simulated turns | US3-AC1, FR-004, SC-003 | example | DONE  | `test/data/providers/planner/planner_provider_test.dart::PlanState — SC-003 persists across turns / state threaded through 5 simulated turns is preserved` |

### `lib/src/domain/repositories/plan_state_repository.dart`, `lib/src/domain/services/planner_service.dart`, `lib/src/data/providers/planner/planner_provider.dart` (clean-arch layers)

| id  | behavior                                                                                  | traces     | kind    | state | test                                                                                                                       |
| --- | ----------------------------------------------------------------------------------------- | ---------- | ------- | ----- | -------------------------------------------------------------------------------------------------------------------------- |
| U8  | `PlannerProvider` is a `PlannerService`; `current`/`mode` throw `UnimplementedError` (stub); `PlannerService` and `PlanStateRepository` usable as type bounds | plan Phase 1 | example | DONE  | `test/data/providers/planner/planner_provider_test.dart::Clean-architecture layers / PlannerProvider is a PlannerService` |

## Invariants and edge cases still to place

- None outstanding: step status transitions, count accuracy, 5-turn persistence, and
  plan-mode semantics are fully covered by U1–U8.

## Out of scope

- Engine-loop wiring of `PlanChangedEvent` into the sealed `EngineEvent` union (spec 045
  owns that library).
- The `write_todos` tool's runtime execution semantics (consumed by spec 002 engine loop).

## Discrepancies (spec vs shipped code — reported, not followed)

- None material. The shipped `PlannerProvider` matches `plan.md` (concrete stub with
  `UnimplementedError` bodies), unlike the StopPolicy provider (spec 014-stop-policy-clean-arch-layers),
  which ships a datasource-consuming provider. The list records the shipped behavior.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md` at planning time:

- Single test: `dart test {file} -n "{name}"`
- Full suite: `dart test`
- Coverage: `dart test --coverage=.dart_coverage {files}` (format with
  `dart run coverage:format_coverage --packages=.dart_tool/package_config.json --report-on=lib --in=.dart_coverage -l`)
- Mutation / property-based: **not available** in this repo (no `mutation_test` /
  `glados` in the lockfile).
