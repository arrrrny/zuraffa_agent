# Implementation Plan: Grader sealed (exact/schema/model-judge)
**Branch**: `062-grader_sealed` | **Date**: 2026-08-24

## Summary
Hand-curate the `GraderSealed` value object (R6 spec-exact) + `GraderSealedService` + `GraderSealedProvider`. Pattern mirrors spec 033 (SteeringQueue + SteeringMessage): plain Dart value objects, no @Zorphy codegen, compiles without build_runner.

## Phase 1 - Design
- **GraderSealed** (value object): 4 fields, value equality across all of them.
- **Service** (`GraderSealedService`): abstract, two NoParams-param methods - current(NoParams) returns the current snapshot, count(NoParams) returns the count.
- **Provider** (`GraderSealedProvider`): concrete stub implementing `GraderSealedService` with matching NoParams signatures; bodies throw UnimplementedError.

## Phase 2 - Tasks
See `tasks.md`.
