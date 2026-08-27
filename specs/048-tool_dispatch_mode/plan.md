# Implementation Plan: ToolDispatchMode (sequential/parallel)
**Branch**: `feat/specs-046-047-048-049` | **Date**: 2026-08-28

## Technical Context
- **Repo**: zuraffa_agent — clean-architecture providers/entities/services, engine layer, MCP transport, build_runner codegen, test harness (dart test + mocktail).
- **Pattern**: mirrors spec 033 (SteeringQueue + SteeringMessage): plain Dart value objects, no @Zorphy codegen, compiles without build_runner.
- **Engine layer**: `lib/src/engine/tool_dispatcher.dart` provides the abstract ToolDispatcher interface with dispatch/dispatchBatch/validateSchema/checkRiskTier.
- **Zorphy codegen**: ToolDispatchResult uses @Zorphy(generateJson: true, generateCompareTo: true). Do NOT hand-edit generated files (.g.dart, .zorphy.dart); regenerate via `dart run build_runner build --delete-conflicting-outputs`.

## Summary
Hand-curate the `ToolDispatchMode` value object (R3 spec-exact) + `ToolDispatchModeService` + `ToolDispatchModeProvider`. Plus engine-layer abstract interface tests and ToolDispatchResult JSON round-trip tests.

## Phase 1 - Design
- **ToolDispatchMode** (value object): 4 fields, value equality across all of them.
- **Service** (`ToolDispatchModeService`): abstract, two NoParams-param methods.
- **Provider** (`ToolDispatchModeProvider`): concrete stub implementing `ToolDispatchModeService`.
- **Engine ToolDispatcher** (abstract interface): dispatch, dispatchBatch, validateSchema, checkRiskTier.
- **ToolCall** (value object): toolName, arguments, executionMode.
- **ToolDispatchResult** (Zorphy entity): success, result, error, artifactRefs — JSON round-trip.

## Phase 2 - Tasks
See `tasks.md`.
