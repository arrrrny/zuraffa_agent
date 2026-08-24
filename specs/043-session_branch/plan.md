# Implementation Plan: SessionBranch (fork/switch/resume)
**Branch**: `043-session_branch` | **Date**: 2026-08-24

## Summary
Hand-curate the `SessionBranch` value object (R1 spec-exact) + `SessionBranchService` + `SessionBranchProvider`. Pattern mirrors spec 033 (SteeringQueue + SteeringMessage): plain Dart value objects, no @Zorphy codegen, compiles without build_runner.

## Phase 1 - Design
- **SessionBranch** (value object): 5 fields, value equality across all of them.
- **Service** (`SessionBranchService`): abstract, two NoParams-param methods - current(NoParams) returns the current snapshot, count(NoParams) returns the count.
- **Provider** (`SessionBranchProvider`): concrete stub implementing `SessionBranchService` with matching NoParams signatures; bodies throw UnimplementedError.

## Phase 2 - Tasks
See `tasks.md`.
