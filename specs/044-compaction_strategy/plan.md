# Implementation Plan: CompactionStrategy (selective retain/summarize)
**Branch**: `044-compaction_strategy` | **Date**: 2026-08-24

## Summary
Hand-curate the `CompactionStrategy` value object (R1 spec-exact) + `CompactionStrategyService` + `CompactionStrategyProvider`. Pattern mirrors spec 033 (SteeringQueue + SteeringMessage): plain Dart value objects, no @Zorphy codegen, compiles without build_runner.

## Phase 1 - Design
- **CompactionStrategy** (value object): 6 fields, value equality across all of them.
- **Service** (`CompactionStrategyService`): abstract, two NoParams-param methods - current(NoParams) returns the current snapshot, count(NoParams) returns the count.
- **Provider** (`CompactionStrategyProvider`): concrete stub implementing `CompactionStrategyService` with matching NoParams signatures; bodies throw UnimplementedError.

## Phase 2 - Tasks
See `tasks.md`.
