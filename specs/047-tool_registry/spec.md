# Feature Specification: ToolRegistry (single namespace)

**Branch**: `047-tool_registry` | **Date**: 2026-08-24

## Summary
Single-namespace tool registry — DDA, generated, and remote-MCP tools all live behind one lookup (epic #3 §R3.1, issue #4 US1). The engine queries by name and gets back a typed AgentTool with JSON Schema. This advances epic issue #4 (Tools & MCP). Pattern: hand-curated plain Dart value object (no @Zorphy), abstract service interface with NoParams parameters, concrete provider stub throwing UnimplementedError, regression tests for value equality + clean-arch layering.

## Files
- `lib/src/domain/entities/tool_registry/tool_registry.dart` - `ToolRegistry` value object (5 fields; value-based equality).
- `lib/src/domain/services/tool_registry_service.dart` - abstract `ToolRegistryService` (current(NoParams), count(NoParams)).
- `lib/src/data/providers/tool_registry/tool_registry_provider.dart` - concrete `ToolRegistryProvider` stub (UnimplementedError bodies).
- `test/data/providers/tool_registry/tool_registry_provider_test.dart` - 5 regression tests (2 entity equality + 3 clean-arch).
- `specs/047-tool_registry/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` - No issues
- `dart test` - All pre-existing + 5 new tests pass

## Advances #4 (Tools & MCP)
