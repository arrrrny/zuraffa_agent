# Implementation Plan: YamlAgentSpec (declarative + extends)
**Branch**: `057-yaml_agent_spec` | **Date**: 2026-08-24

## Summary
Hand-curate the `YamlAgentSpec` value object (R5 spec-exact) + `YamlAgentSpecService` + `YamlAgentSpecProvider`. Pattern mirrors spec 033 (SteeringQueue + SteeringMessage): plain Dart value objects, no @Zorphy codegen, compiles without build_runner.

## Phase 1 - Design
- **YamlAgentSpec** (value object): 5 fields, value equality across all of them.
- **Service** (`YamlAgentSpecService`): abstract, two NoParams-param methods - current(NoParams) returns the current snapshot, count(NoParams) returns the count.
- **Provider** (`YamlAgentSpecProvider`): concrete stub implementing `YamlAgentSpecService` with matching NoParams signatures; bodies throw UnimplementedError.

## Phase 2 - Tasks
See `tasks.md`.
