# Implementation Plan: ToolRegistry (single namespace)
**Branch**: `047-tool_registry` | **Date**: 2026-08-24

## Summary
Hand-curate the `ToolRegistry` value object (R3 spec-exact) + `ToolRegistryService` + `ToolRegistryProvider`. Pattern mirrors spec 033 (SteeringQueue + SteeringMessage): plain Dart value objects, no @Zorphy codegen, compiles without build_runner.

## Phase 1 - Design
- **ToolRegistry** (value object): 5 fields, value equality across all of them.
- **Service** (`ToolRegistryService`): abstract, two NoParams-param methods - current(NoParams) returns the current snapshot, count(NoParams) returns the count.
- **Provider** (`ToolRegistryProvider`): concrete stub implementing `ToolRegistryService` with matching NoParams signatures; bodies throw UnimplementedError.

## Phase 2 - Tasks
See `tasks.md`.
