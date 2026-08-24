# Implementation Plan: FallbackChain (advance policy + state)
**Branch**: `053-fallback_chain` | **Date**: 2026-08-24

## Summary
Hand-curate the `FallbackChain` value object (R4 spec-exact) + `FallbackChainService` + `FallbackChainProvider`. Pattern mirrors spec 033 (SteeringQueue + SteeringMessage): plain Dart value objects, no @Zorphy codegen, compiles without build_runner.

## Phase 1 - Design
- **FallbackChain** (value object): 5 fields, value equality across all of them.
- **Service** (`FallbackChainService`): abstract, two NoParams-param methods - current(NoParams) returns the current snapshot, count(NoParams) returns the count.
- **Provider** (`FallbackChainProvider`): concrete stub implementing `FallbackChainService` with matching NoParams signatures; bodies throw UnimplementedError.

## Phase 2 - Tasks
See `tasks.md`.
