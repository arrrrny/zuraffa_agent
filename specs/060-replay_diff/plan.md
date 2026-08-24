# Implementation Plan: ReplayDiff (input drift detection)
**Branch**: `060-replay_diff` | **Date**: 2026-08-24

## Summary
Hand-curate the `ReplayDiff` value object (R6 spec-exact) + `ReplayDiffService` + `ReplayDiffProvider`. Pattern mirrors spec 033 (SteeringQueue + SteeringMessage): plain Dart value objects, no @Zorphy codegen, compiles without build_runner.

## Phase 1 - Design
- **ReplayDiff** (value object): 4 fields, value equality across all of them.
- **Service** (`ReplayDiffService`): abstract, two NoParams-param methods - current(NoParams) returns the current snapshot, count(NoParams) returns the count.
- **Provider** (`ReplayDiffProvider`): concrete stub implementing `ReplayDiffService` with matching NoParams signatures; bodies throw UnimplementedError.

## Phase 2 - Tasks
See `tasks.md`.
