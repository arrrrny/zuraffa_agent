# Implementation Plan: OversizedResultPolicy (summarize+artifactRef)
**Branch**: `050-oversized_result_policy` | **Date**: 2026-08-24

## Summary
Hand-curate the `OversizedResultPolicy` value object (R3 spec-exact) + `OversizedResultPolicyService` + `OversizedResultPolicyProvider`. Pattern mirrors spec 033 (SteeringQueue + SteeringMessage): plain Dart value objects, no @Zorphy codegen, compiles without build_runner.

## Phase 1 - Design
- **OversizedResultPolicy** (value object): 4 fields, value equality across all of them.
- **Service** (`OversizedResultPolicyService`): abstract, two NoParams-param methods - current(NoParams) returns the current snapshot, count(NoParams) returns the count.
- **Provider** (`OversizedResultPolicyProvider`): concrete stub implementing `OversizedResultPolicyService` with matching NoParams signatures; bodies throw UnimplementedError.

## Phase 2 - Tasks
See `tasks.md`.
