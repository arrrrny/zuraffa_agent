# Implementation Plan: RecordedTraffic (LLM + tool capture)
**Branch**: `059-recorded_traffic` | **Date**: 2026-08-24

## Summary
Hand-curate the `RecordedTraffic` value object (R6 spec-exact) + `RecordedTrafficService` + `RecordedTrafficProvider`. Pattern mirrors spec 033 (SteeringQueue + SteeringMessage): plain Dart value objects, no @Zorphy codegen, compiles without build_runner.

## Phase 1 - Design
- **RecordedTraffic** (value object): 5 fields, value equality across all of them.
- **Service** (`RecordedTrafficService`): abstract, two NoParams-param methods - current(NoParams) returns the current snapshot, count(NoParams) returns the count.
- **Provider** (`RecordedTrafficProvider`): concrete stub implementing `RecordedTrafficService` with matching NoParams signatures; bodies throw UnimplementedError.

## Phase 2 - Tasks
See `tasks.md`.
