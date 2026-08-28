# Implementation Plan: ToolRegistry (single namespace)
**Branch**: `feat/specs-046-047-048-049` | **Date**: 2026-08-28

## Technical Context
- **Repo**: zuraffa_agent — clean-architecture providers/entities/services, engine layer, MCP transport, build_runner codegen, test harness (dart test + mocktail).
- **Pattern**: mirrors spec 033 (SteeringQueue + SteeringMessage): plain Dart value objects, no @Zorphy codegen, compiles without build_runner.
- **Engine layer**: `lib/src/engine/tool_registry.dart` provides the abstract ToolRegistry interface with register/resolve/list semantics and a NamespaceCollisionEvent value object.

## Summary
Hand-curate the `ToolRegistry` value object (R3 spec-exact) + `ToolRegistryService` + `ToolRegistryProvider`. Plus engine-layer abstract interface tests.

## Phase 1 - Design
- **ToolRegistry** (value object): 5 fields, value equality across all of them.
- **Service** (`ToolRegistryService`): abstract, two NoParams-param methods - current(NoParams) returns the current snapshot, count(NoParams) returns the count.
- **Provider** (`ToolRegistryProvider`): concrete stub implementing `ToolRegistryService` with matching NoParams signatures; bodies throw UnimplementedError.
- **Engine ToolRegistry** (abstract interface): registerDdaTool, registerGeneratedTool, registerMcpTool, unregister, resolve, list, onCollision.
- **NamespaceCollisionEvent** (value object): toolName, sources, resolution.

## Phase 2 - Tasks
See `tasks.md`.
