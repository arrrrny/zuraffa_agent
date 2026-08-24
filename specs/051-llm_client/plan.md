# Implementation Plan: LlmClient interface + LlmRequest/LlmResponse
**Branch**: `051-llm_client` | **Date**: 2026-08-24

## Summary
Hand-curate the `LlmClient` value object (R4 spec-exact) + `LlmClientService` + `LlmClientProvider`. Pattern mirrors spec 033 (SteeringQueue + SteeringMessage): plain Dart value objects, no @Zorphy codegen, compiles without build_runner.

## Phase 1 - Design
- **LlmClient** (value object): 5 fields, value equality across all of them.
- **Service** (`LlmClientService`): abstract, two NoParams-param methods - current(NoParams) returns the current snapshot, count(NoParams) returns the count.
- **Provider** (`LlmClientProvider`): concrete stub implementing `LlmClientService` with matching NoParams signatures; bodies throw UnimplementedError.

## Phase 2 - Tasks
See `tasks.md`.
