# Implementation Plan: ToolDispatchMode (sequential/parallel)
**Branch**: `048-tool_dispatch_mode` | **Date**: 2026-08-24

## Summary
Hand-curate the `ToolDispatchMode` value object (R3 spec-exact) + `ToolDispatchModeService` + `ToolDispatchModeProvider`. Pattern mirrors spec 033 (SteeringQueue + SteeringMessage): plain Dart value objects, no @Zorphy codegen, compiles without build_runner.

## Phase 1 - Design
- **ToolDispatchMode** (value object): 4 fields, value equality across all of them.
- **Service** (`ToolDispatchModeService`): abstract, two NoParams-param methods - current(NoParams) returns the current snapshot, count(NoParams) returns the count.
- **Provider** (`ToolDispatchModeProvider`): concrete stub implementing `ToolDispatchModeService` with matching NoParams signatures; bodies throw UnimplementedError.

## Phase 2 - Tasks
See `tasks.md`.
