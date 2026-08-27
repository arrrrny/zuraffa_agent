# Implementation Plan: Planner/TODO System
**Branch**: `014-planner-todo-system` | **Date**: 2026-08-27 | **Spec**: [spec.md](./spec.md)

## Summary
Hand-curate the Planner/TODO value-object set (spec 014, gap-analysis row 7 — `write_todos` tool with `PlanState`, modeled after dart_agent_core's planner) plus its clean-architecture layers (repository, service, provider). zfa v6.0.0 cannot emit these surfaces (`zfa entity create` rejects `Duration`/sealed shapes, `zfa make` crashes — issues #13/#14), so the set ships hand-curated per the established PR #47/#48/#51 pattern.

## Phase 1 — Design

### Value objects (`lib/src/domain/entities/planner/`, one concept per file)
- **`StepStatus`** (enum) — `pending`, `inProgress`, `completed`, `cancelled` (FR-002). `isTerminal` getter for completed/cancelled.
- **`PlanStep`** — `id`, `description`, `status` (defaults `pending`); `copyWith` returns a new step (pure transition, CircuitBreaker pattern); value equality.
- **`PlanState`** — immutable snapshot: `id`, `steps`, `currentStepId`. Derived getters answer SC-001 directly: `totalSteps`, `pendingCount`, `inProgressCount`, `completedCount`, `cancelledCount`, `progressFraction` (completed/total, 0.0 when empty), `currentStep` (resolves `currentStepId`), `isComplete`. Mutation methods (`withSteps`, `updateStep`, `markStep`) return NEW instances — persistence across turns is value threading (SteeringQueue pattern, FR-004): the repository persists the latest snapshot, the engine threads it turn-to-turn.
- **`PlanMode`** (enum) — `none`, `auto`, `must` (FR-003). `injectsPlannerTools` (false only for `none`), `requiresPlanningBeforeExecution` (true only for `must`) — the two levers SC-002 asserts.
- **`PlanChangedEvent`** — `emittedAt`, `previous`, `next` (FR-005). Domain-level event value object; wiring into the sealed `EngineEvent` union happens with the engine-loop spec (045) which owns that library.
- **`WriteTodosTool`** — canonical `AgentTool` declaration (id `write_todos`, `RiskTier.safe`, sequential, JSON Schema requiring a `todos` array) — FR-001's injectable surface, typed against the existing AgentTool value object (PR #52).
- **`Planner`** — `mode`; exposes `writeTodosTool` (the declaration) and `toolsForInjection()` (`[writeTodosTool]` when mode injects, empty otherwise); planning-required semantics delegate to `PlanMode`.

### Clean-arch layers (PR #48 StopPolicy pattern)
- `PlanStateRepository` (abstract) — `getCurrent(id)`, `update(state)`, `reset(id)`; value-object surface, no CRUD.
- `PlannerService` (abstract) — `current(NoParams)`, `mode(NoParams)`; parameterless NoParams signatures (PR #32 pattern).
- `PlannerProvider` (concrete stub) — implements `PlannerService`, `UnimplementedError` bodies.

## Phase 2 — Tasks
See `tasks.md`.
