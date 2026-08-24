# Implementation Plan: SubAgentInstance (resumable)
**Branch**: `056-sub_agent_instance` | **Date**: 2026-08-24

## Summary
Hand-curate the `SubAgentInstance` value object (R5 spec-exact) + `SubAgentInstanceService` + `SubAgentInstanceProvider`. Pattern mirrors spec 033 (SteeringQueue + SteeringMessage): plain Dart value objects, no @Zorphy codegen, compiles without build_runner.

## Phase 1 - Design
- **SubAgentInstance** (value object): 5 fields, value equality across all of them.
- **Service** (`SubAgentInstanceService`): abstract, two NoParams-param methods - current(NoParams) returns the current snapshot, count(NoParams) returns the count.
- **Provider** (`SubAgentInstanceProvider`): concrete stub implementing `SubAgentInstanceService` with matching NoParams signatures; bodies throw UnimplementedError.

## Phase 2 - Tasks
See `tasks.md`.
