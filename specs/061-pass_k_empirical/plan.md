# Implementation Plan: PassKEmpirical (pass^k metric)
**Branch**: `061-pass_k_empirical` | **Date**: 2026-08-24

## Summary
Hand-curate the `PassKEmpirical` value object (R6 spec-exact) + `PassKEmpiricalService` + `PassKEmpiricalProvider`. Pattern mirrors spec 033 (SteeringQueue + SteeringMessage): plain Dart value objects, no @Zorphy codegen, compiles without build_runner.

## Phase 1 - Design
- **PassKEmpirical** (value object): 5 fields, value equality across all of them.
- **Service** (`PassKEmpiricalService`): abstract, two NoParams-param methods - current(NoParams) returns the current snapshot, count(NoParams) returns the count.
- **Provider** (`PassKEmpiricalProvider`): concrete stub implementing `PassKEmpiricalService` with matching NoParams signatures; bodies throw UnimplementedError.

## Phase 2 - Tasks
See `tasks.md`.
