# Implementation Plan: LoopSafetyRails typed outcomes
**Branch**: `feat/specs-046-047-048-049` | **Date**: 2026-08-28

## Technical Context
- **Repo**: zuraffa_agent — clean-architecture providers/entities/services, engine layer, MCP transport, build_runner codegen, test harness (dart test + mocktail).
- **Pattern**: mirrors spec 033 (SteeringQueue + SteeringMessage): plain Dart value objects, no @Zorphy codegen, compiles without build_runner.

## Summary
Hand-curate the `LoopSafetyRails` value object (R2 spec-exact) + `LoopSafetyRailsService` + `LoopSafetyRailsProvider`. Pattern mirrors spec 033 (SteeringQueue + SteeringMessage): plain Dart value objects, no @Zorphy codegen, compiles without build_runner.

## Phase 1 - Design
- **LoopSafetyRails** (value object): 4 fields, value equality across all of them.
- **Service** (`LoopSafetyRailsService`): abstract, two NoParams-param methods - current(NoParams) returns the current snapshot, count(NoParams) returns the count.
- **Provider** (`LoopSafetyRailsProvider`): concrete stub implementing `LoopSafetyRailsService` with matching NoParams signatures; bodies throw UnimplementedError.

## Phase 2 - Tasks
See `tasks.md`.
