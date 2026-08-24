# Implementation Plan: HealthSnapshot (chain state)
**Branch**: `054-health_snapshot` | **Date**: 2026-08-24

## Summary
Hand-curate the `HealthSnapshot` value object (R4 spec-exact) + `HealthSnapshotService` + `HealthSnapshotProvider`. Pattern mirrors spec 033 (SteeringQueue + SteeringMessage): plain Dart value objects, no @Zorphy codegen, compiles without build_runner.

## Phase 1 - Design
- **HealthSnapshot** (value object): 5 fields, value equality across all of them.
- **Service** (`HealthSnapshotService`): abstract, two NoParams-param methods - current(NoParams) returns the current snapshot, count(NoParams) returns the count.
- **Provider** (`HealthSnapshotProvider`): concrete stub implementing `HealthSnapshotService` with matching NoParams signatures; bodies throw UnimplementedError.

## Phase 2 - Tasks
See `tasks.md`.
