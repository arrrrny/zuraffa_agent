**Template Version**: `zuraffa-1.0`

# Feature Specification: ToolRegistry (single namespace)

**Branch**: `feat/specs-046-047-048-049` | **Date**: 2026-08-28

## Summary
Single-namespace tool registry — DDA, generated, and remote-MCP tools all live behind one lookup (epic #3 §R3.1, issue #4 US1). The engine queries by name and gets back a typed AgentTool with JSON Schema. This advances epic issue #4 (Tools & MCP). Pattern: hand-curated plain Dart value object (no @Zorphy), abstract service interface with NoParams parameters, concrete provider stub throwing UnimplementedError, regression tests for value equality + clean-arch layering.

## Acceptance Criteria

| id | criterion | verified |
|----|-----------|----------|
1. **Given** the implemented feature **When** its acceptance criterion applies — | ToolRegistry is a plain Dart value object with 5 required fields (id, toolNames, ddToolCount, generatedToolCount, mcpToolCount) and a const constructor | yes | — **Then** the pinned regression suite confirms it.
   **Type**: acceptance
2. **Given** the implemented feature **When** its acceptance criterion applies — | Value equality holds when all 5 fields are identical; inequality is detected when any field differs | yes | — **Then** the pinned regression suite confirms it.
   **Type**: acceptance
3. **Given** the implemented feature **When** its acceptance criterion applies — | hashCode is consistent with == (equal instances share hashCode) | yes | — **Then** the pinned regression suite confirms it.
   **Type**: acceptance
4. **Given** the implemented feature **When** its acceptance criterion applies — | ToolRegistryService is abstract, mixes in Loggable and FailureHandler, declares current(NoParams) and count(NoParams) | yes | — **Then** the pinned regression suite confirms it.
   **Type**: acceptance
5. **Given** the implemented feature **When** its acceptance criterion applies — | ToolRegistryProvider implements ToolRegistryService and throws UnimplementedError for both methods | yes | — **Then** the pinned regression suite confirms it.
   **Type**: acceptance
6. **Given** the implemented feature **When** its acceptance criterion applies — | toString includes id and toolNames | yes | — **Then** the pinned regression suite confirms it.
   **Type**: acceptance
7. **Given** the implemented feature **When** its acceptance criterion applies — | Engine ToolRegistry abstract interface declares registerDdaTool, registerGeneratedTool, registerMcpTool, unregister, resolve, list, onCollision | yes | — **Then** the pinned regression suite confirms it.
   **Type**: acceptance
8. **Given** the implemented feature **When** its acceptance criterion applies — | NamespaceCollisionEvent is a value object with toolName, sources, resolution fields | yes | — **Then** the pinned regression suite confirms it.
   **Type**: acceptance

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
## Acceptance Scenarios

> Derived verbatim from the feature's pinned regression suite.
> Behaviors are inherited-green: the cited tests pass unmodified in
> the repo suite (dart test, 1201 passing).
9. **Given** the feature implementation under its clean-architecture seams **When** ToolRegistry equality is value-based across all fields **Then** the pinned regression test passes (`test/data/providers/tool_registry/tool_registry_provider_test.dart`).
   **Type**: acceptance
10. **Given** the feature implementation under its clean-architecture seams **When** ToolRegistry inequality differs when a field changes **Then** the pinned regression test passes (`test/data/providers/tool_registry/tool_registry_provider_test.dart`).
   **Type**: acceptance
11. **Given** the feature implementation under its clean-architecture seams **When** ToolRegistry inequality detected per-field: id **Then** the pinned regression test passes (`test/data/providers/tool_registry/tool_registry_provider_test.dart`).
   **Type**: acceptance
12. **Given** the feature implementation under its clean-architecture seams **When** ToolRegistry inequality detected per-field: toolNames **Then** the pinned regression test passes (`test/data/providers/tool_registry/tool_registry_provider_test.dart`).
   **Type**: acceptance
13. **Given** the feature implementation under its clean-architecture seams **When** ToolRegistry inequality detected per-field: ddToolCount **Then** the pinned regression test passes (`test/data/providers/tool_registry/tool_registry_provider_test.dart`).
   **Type**: acceptance
14. **Given** the feature implementation under its clean-architecture seams **When** ToolRegistry empty toolNames list is valid **Then** the pinned regression test passes (`test/data/providers/tool_registry/tool_registry_provider_test.dart`).
   **Type**: acceptance
15. **Given** the feature implementation under its clean-architecture seams **When** ToolRegistry zero counts are valid **Then** the pinned regression test passes (`test/data/providers/tool_registry/tool_registry_provider_test.dart`).
   **Type**: acceptance
16. **Given** the feature implementation under its clean-architecture seams **When** toString includes id and toolNames **Then** the pinned regression test passes (`test/data/providers/tool_registry/tool_registry_provider_test.dart`).
   **Type**: acceptance
17. **Given** the feature implementation under its clean-architecture seams **When** ToolRegistryProvider is a ToolRegistryService **Then** the pinned regression test passes (`test/data/providers/tool_registry/tool_registry_provider_test.dart`).
   **Type**: acceptance
18. **Given** the feature implementation under its clean-architecture seams **When** ToolRegistryProvider.current returns the active registry snapshot **Then** the pinned regression test passes (`test/data/providers/tool_registry/tool_registry_provider_test.dart`).
   **Type**: acceptance
19. **Given** the feature implementation under its clean-architecture seams **When** ToolRegistryProvider.current honours an injected registry **Then** the pinned regression test passes (`test/data/providers/tool_registry/tool_registry_provider_test.dart`).
   **Type**: acceptance
20. **Given** the feature implementation under its clean-architecture seams **When** ToolRegistryProvider.count returns 1 **Then** the pinned regression test passes (`test/data/providers/tool_registry/tool_registry_provider_test.dart`).
   **Type**: acceptance
21. **Given** the feature implementation under its clean-architecture seams **When** NamespaceCollisionEvent holds toolName, sources, resolution **Then** the pinned regression test passes (`test/data/providers/tool_registry/tool_registry_provider_test.dart`).
   **Type**: acceptance
22. **Given** the feature implementation under its clean-architecture seams **When** NamespaceCollisionEvent const constructor **Then** the pinned regression test passes (`test/data/providers/tool_registry/tool_registry_provider_test.dart`).
   **Type**: acceptance
