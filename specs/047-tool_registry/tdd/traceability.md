# Traceability: 047-tool_registry

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:18a3e2bdc46875a7c8be62b08cdf572fc4651b7ba00180eb8fe40777fd33fc23
statements: 22
automated: 22
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 14 | 1. **Given** the implemented feature **When** its acceptance criterion applies — \| ToolRegistry is a plain Dart value object with 5 required fields (id, toolNames, ddToolCount, generatedToolCount, mcpToolCount) and a const constructor \| yes \| — **Then** the pinned regression suite confirms it. | A1 | automated |
| AC-2 | 15 | 2. **Given** the implemented feature **When** its acceptance criterion applies — \| Value equality holds when all 5 fields are identical; inequality is detected when any field differs \| yes \| — **Then** the pinned regression suite confirms it. | A2 | automated |
| AC-3 | 16 | 3. **Given** the implemented feature **When** its acceptance criterion applies — \| hashCode is consistent with == (equal instances share hashCode) \| yes \| — **Then** the pinned regression suite confirms it. | A3 | automated |
| AC-4 | 17 | 4. **Given** the implemented feature **When** its acceptance criterion applies — \| ToolRegistryService is abstract, mixes in Loggable and FailureHandler, declares current(NoParams) and count(NoParams) \| yes \| — **Then** the pinned regression suite confirms it. | A4 | automated |
| AC-5 | 18 | 5. **Given** the implemented feature **When** its acceptance criterion applies — \| ToolRegistryProvider implements ToolRegistryService and throws UnimplementedError for both methods \| yes \| — **Then** the pinned regression suite confirms it. | A5 | automated |
| AC-6 | 19 | 6. **Given** the implemented feature **When** its acceptance criterion applies — \| toString includes id and toolNames \| yes \| — **Then** the pinned regression suite confirms it. | A6 | automated |
| AC-7 | 20 | 7. **Given** the implemented feature **When** its acceptance criterion applies — \| Engine ToolRegistry abstract interface declares registerDdaTool, registerGeneratedTool, registerMcpTool, unregister, resolve, list, onCollision \| yes \| — **Then** the pinned regression suite confirms it. | A7 | automated |
| AC-8 | 21 | 8. **Given** the implemented feature **When** its acceptance criterion applies — \| NamespaceCollisionEvent is a value object with toolName, sources, resolution fields \| yes \| — **Then** the pinned regression suite confirms it. | A8 | automated |
| AC-9 | 43 | 9. **Given** the feature implementation under its clean-architecture seams **When** ToolRegistry equality is value-based across all fields **Then** the pinned regression test passes (`test/data/providers/tool_registry/tool_registry_provider_test.dart`). | A9 | automated |
| AC-10 | 44 | 10. **Given** the feature implementation under its clean-architecture seams **When** ToolRegistry inequality differs when a field changes **Then** the pinned regression test passes (`test/data/providers/tool_registry/tool_registry_provider_test.dart`). | A10 | automated |
| AC-11 | 45 | 11. **Given** the feature implementation under its clean-architecture seams **When** ToolRegistry inequality detected per-field: id **Then** the pinned regression test passes (`test/data/providers/tool_registry/tool_registry_provider_test.dart`). | A11 | automated |
| AC-12 | 46 | 12. **Given** the feature implementation under its clean-architecture seams **When** ToolRegistry inequality detected per-field: toolNames **Then** the pinned regression test passes (`test/data/providers/tool_registry/tool_registry_provider_test.dart`). | A12 | automated |
| AC-13 | 47 | 13. **Given** the feature implementation under its clean-architecture seams **When** ToolRegistry inequality detected per-field: ddToolCount **Then** the pinned regression test passes (`test/data/providers/tool_registry/tool_registry_provider_test.dart`). | A13 | automated |
| AC-14 | 48 | 14. **Given** the feature implementation under its clean-architecture seams **When** ToolRegistry empty toolNames list is valid **Then** the pinned regression test passes (`test/data/providers/tool_registry/tool_registry_provider_test.dart`). | A14 | automated |
| AC-15 | 49 | 15. **Given** the feature implementation under its clean-architecture seams **When** ToolRegistry zero counts are valid **Then** the pinned regression test passes (`test/data/providers/tool_registry/tool_registry_provider_test.dart`). | A15 | automated |
| AC-16 | 50 | 16. **Given** the feature implementation under its clean-architecture seams **When** toString includes id and toolNames **Then** the pinned regression test passes (`test/data/providers/tool_registry/tool_registry_provider_test.dart`). | A16 | automated |
| AC-17 | 51 | 17. **Given** the feature implementation under its clean-architecture seams **When** ToolRegistryProvider is a ToolRegistryService **Then** the pinned regression test passes (`test/data/providers/tool_registry/tool_registry_provider_test.dart`). | A17 | automated |
| AC-18 | 52 | 18. **Given** the feature implementation under its clean-architecture seams **When** ToolRegistryProvider.current returns the active registry snapshot **Then** the pinned regression test passes (`test/data/providers/tool_registry/tool_registry_provider_test.dart`). | A18 | automated |
| AC-19 | 53 | 19. **Given** the feature implementation under its clean-architecture seams **When** ToolRegistryProvider.current honours an injected registry **Then** the pinned regression test passes (`test/data/providers/tool_registry/tool_registry_provider_test.dart`). | A19 | automated |
| AC-20 | 54 | 20. **Given** the feature implementation under its clean-architecture seams **When** ToolRegistryProvider.count returns 1 **Then** the pinned regression test passes (`test/data/providers/tool_registry/tool_registry_provider_test.dart`). | A20 | automated |
| AC-21 | 55 | 21. **Given** the feature implementation under its clean-architecture seams **When** NamespaceCollisionEvent holds toolName, sources, resolution **Then** the pinned regression test passes (`test/data/providers/tool_registry/tool_registry_provider_test.dart`). | A21 | automated |
| AC-22 | 56 | 22. **Given** the feature implementation under its clean-architecture seams **When** NamespaceCollisionEvent const constructor **Then** the pinned regression test passes (`test/data/providers/tool_registry/tool_registry_provider_test.dart`). | A22 | automated |

