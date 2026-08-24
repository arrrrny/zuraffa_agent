# Implementation Plan: ReplayCliSurface (zfa agent replay)
**Branch**: `063-replay_cli_surface` | **Date**: 2026-08-24

## Summary
Hand-curate the `ReplayCliSurface` value object (R6 spec-exact) + `ReplayCliSurfaceService` + `ReplayCliSurfaceProvider`. Pattern mirrors spec 033 (SteeringQueue + SteeringMessage): plain Dart value objects, no @Zorphy codegen, compiles without build_runner.

## Phase 1 - Design
- **ReplayCliSurface** (value object): 4 fields, value equality across all of them.
- **Service** (`ReplayCliSurfaceService`): abstract, two NoParams-param methods - current(NoParams) returns the current snapshot, count(NoParams) returns the count.
- **Provider** (`ReplayCliSurfaceProvider`): concrete stub implementing `ReplayCliSurfaceService` with matching NoParams signatures; bodies throw UnimplementedError.

## Phase 2 - Tasks
See `tasks.md`.
