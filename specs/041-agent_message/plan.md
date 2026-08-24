# Implementation Plan: AgentMessage (multimodal parts)
**Branch**: `041-agent_message` | **Date**: 2026-08-24

## Summary
Hand-curate the `AgentMessage` value object (R1 spec-exact) + `AgentMessageService` + `AgentMessageProvider`. Pattern mirrors spec 033 (SteeringQueue + SteeringMessage): plain Dart value objects, no @Zorphy codegen, compiles without build_runner.

## Phase 1 - Design
- **AgentMessage** (value object): 3 fields, value equality across all of them.
- **Service** (`AgentMessageService`): abstract, two NoParams-param methods - current(NoParams) returns the current snapshot, count(NoParams) returns the count.
- **Provider** (`AgentMessageProvider`): concrete stub implementing `AgentMessageService` with matching NoParams signatures; bodies throw UnimplementedError.

## Phase 2 - Tasks
See `tasks.md`.
