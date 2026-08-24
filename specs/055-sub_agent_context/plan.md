# Implementation Plan: SubAgentContext (isolated context)
**Branch**: `055-sub_agent_context` | **Date**: 2026-08-24

## Summary
Hand-curate the `SubAgentContext` value object (R5 spec-exact) + `SubAgentContextService` + `SubAgentContextProvider`. Pattern mirrors spec 033 (SteeringQueue + SteeringMessage): plain Dart value objects, no @Zorphy codegen, compiles without build_runner.

## Phase 1 - Design
- **SubAgentContext** (value object): 5 fields, value equality across all of them.
- **Service** (`SubAgentContextService`): abstract, two NoParams-param methods - current(NoParams) returns the current snapshot, count(NoParams) returns the count.
- **Provider** (`SubAgentContextProvider`): concrete stub implementing `SubAgentContextService` with matching NoParams signatures; bodies throw UnimplementedError.

## Phase 2 - Tasks
See `tasks.md`.
