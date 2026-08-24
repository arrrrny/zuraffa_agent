# Implementation Plan: EngineLoop (while-loop executor)
**Branch**: `045-engine_loop` | **Date**: 2026-08-24

## Summary
Hand-curate the `EngineLoop` value object (R2 spec-exact) + `EngineLoopService` + `EngineLoopProvider`. Pattern mirrors spec 033 (SteeringQueue + SteeringMessage): plain Dart value objects, no @Zorphy codegen, compiles without build_runner.

## Phase 1 - Design
- **EngineLoop** (value object): 5 fields, value equality across all of them.
- **Service** (`EngineLoopService`): abstract, two NoParams-param methods - current(NoParams) returns the current snapshot, count(NoParams) returns the count.
- **Provider** (`EngineLoopProvider`): concrete stub implementing `EngineLoopService` with matching NoParams signatures; bodies throw UnimplementedError.

## Phase 2 - Tasks
See `tasks.md`.
