# Implementation Plan: DispatchTool (built-in)
**Branch**: `058-dispatch_tool` | **Date**: 2026-08-24

## Summary
Hand-curate the `DispatchTool` value object (R5 spec-exact) + `DispatchToolService` + `DispatchToolProvider`. Pattern mirrors spec 033 (SteeringQueue + SteeringMessage): plain Dart value objects, no @Zorphy codegen, compiles without build_runner.

## Phase 1 - Design
- **DispatchTool** (value object): 4 fields, value equality across all of them.
- **Service** (`DispatchToolService`): abstract, two NoParams-param methods - current(NoParams) returns the current snapshot, count(NoParams) returns the count.
- **Provider** (`DispatchToolProvider`): concrete stub implementing `DispatchToolService` with matching NoParams signatures; bodies throw UnimplementedError.

## Phase 2 - Tasks
See `tasks.md`.
