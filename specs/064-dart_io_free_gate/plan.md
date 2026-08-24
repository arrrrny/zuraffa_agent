# Implementation Plan: DartIoFreeGate (static gate)
**Branch**: `064-dart_io_free_gate` | **Date**: 2026-08-24

## Summary
Hand-curate the `DartIoFreeGate` value object (R6 spec-exact) + `DartIoFreeGateService` + `DartIoFreeGateProvider`. Pattern mirrors spec 033 (SteeringQueue + SteeringMessage): plain Dart value objects, no @Zorphy codegen, compiles without build_runner.

## Phase 1 - Design
- **DartIoFreeGate** (value object): 4 fields, value equality across all of them.
- **Service** (`DartIoFreeGateService`): abstract, two NoParams-param methods - current(NoParams) returns the current snapshot, count(NoParams) returns the count.
- **Provider** (`DartIoFreeGateProvider`): concrete stub implementing `DartIoFreeGateService` with matching NoParams signatures; bodies throw UnimplementedError.

## Phase 2 - Tasks
See `tasks.md`.
