# Feature Specification: ToolRegistry (single namespace)

**Branch**: `feat/specs-046-047-048-049` | **Date**: 2026-08-28

## Summary
Single-namespace tool registry — DDA, generated, and remote-MCP tools all live behind one lookup (epic #3 §R3.1, issue #4 US1). The engine queries by name and gets back a typed AgentTool with JSON Schema. This advances epic issue #4 (Tools & MCP). Pattern: hand-curated plain Dart value object (no @Zorphy), abstract service interface with NoParams parameters, concrete provider stub throwing UnimplementedError, regression tests for value equality + clean-arch layering.

## Acceptance Criteria

| id | criterion | verified |
|----|-----------|----------|
| AC-1 | ToolRegistry is a plain Dart value object with 5 required fields (id, toolNames, ddToolCount, generatedToolCount, mcpToolCount) and a const constructor | yes |
| AC-2 | Value equality holds when all 5 fields are identical; inequality is detected when any field differs | yes |
| AC-3 | hashCode is consistent with == (equal instances share hashCode) | yes |
| AC-4 | ToolRegistryService is abstract, mixes in Loggable and FailureHandler, declares current(NoParams) and count(NoParams) | yes |
| AC-5 | ToolRegistryProvider implements ToolRegistryService and throws UnimplementedError for both methods | yes |
| AC-6 | toString includes id and toolNames | yes |
| AC-7 | Engine ToolRegistry abstract interface declares registerDdaTool, registerGeneratedTool, registerMcpTool, unregister, resolve, list, onCollision | yes |
| AC-8 | NamespaceCollisionEvent is a value object with toolName, sources, resolution fields | yes |

## Files
- `lib/src/domain/entities/tool_registry/tool_registry.dart` - `ToolRegistry` value object (5 fields; value-based equality).
- `lib/src/domain/services/tool_registry_service.dart` - abstract `ToolRegistryService` (current(NoParams), count(NoParams)).
- `lib/src/data/providers/tool_registry/tool_registry_provider.dart` - concrete `ToolRegistryProvider` stub (UnimplementedError bodies).
- `lib/src/engine/tool_registry.dart` - abstract `ToolRegistry` interface + `NamespaceCollisionEvent`.
- `test/data/providers/tool_registry/tool_registry_provider_test.dart` - regression tests (entity equality + clean-arch + toString + engine interface).
- `specs/047-tool_registry/{spec,plan,tasks}.md`.
- `specs/047-tool_registry/tdd/{test-list,verification}.md`.

## Verification
- `dart pub get` clean
- `dart analyze` - No new issues
- `dart test` - All pre-existing + new tests pass

## Advances #4 (Tools & MCP)