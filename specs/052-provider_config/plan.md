# Implementation Plan: ProviderConfig (typed openai/anthropic/gemini)
**Branch**: `052-provider_config` | **Date**: 2026-08-24

## Summary
Hand-curate the `ProviderConfig` value object (R4 spec-exact) + `ProviderConfigService` + `ProviderConfigProvider`. Pattern mirrors spec 033 (SteeringQueue + SteeringMessage): plain Dart value objects, no @Zorphy codegen, compiles without build_runner.

## Phase 1 - Design
- **ProviderConfig** (value object): 5 fields, value equality across all of them.
- **Service** (`ProviderConfigService`): abstract, two NoParams-param methods - current(NoParams) returns the current snapshot, count(NoParams) returns the count.
- **Provider** (`ProviderConfigProvider`): concrete stub implementing `ProviderConfigService` with matching NoParams signatures; bodies throw UnimplementedError.

## Phase 2 - Tasks
See `tasks.md`.
