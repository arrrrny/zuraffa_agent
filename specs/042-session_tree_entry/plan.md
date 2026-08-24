# Implementation Plan: SessionTreeEntry sealed hierarchy
**Branch**: `042-session_tree_entry` | **Date**: 2026-08-24

## Summary
Hand-curate the `SessionTreeEntry` value object (R1 spec-exact) + `SessionTreeEntryService` + `SessionTreeEntryProvider`. Pattern mirrors spec 033 (SteeringQueue + SteeringMessage): plain Dart value objects, no @Zorphy codegen, compiles without build_runner.

## Phase 1 - Design
- **SessionTreeEntry** (value object): 4 fields, value equality across all of them.
- **Service** (`SessionTreeEntryService`): abstract, two NoParams-param methods - current(NoParams) returns the current snapshot, count(NoParams) returns the count.
- **Provider** (`SessionTreeEntryProvider`): concrete stub implementing `SessionTreeEntryService` with matching NoParams signatures; bodies throw UnimplementedError.

## Phase 2 - Tasks
See `tasks.md`.
