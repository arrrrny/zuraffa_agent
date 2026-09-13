# Traceability: 049-mcp_transport

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:0291b6484f5d16d7b124b8fb5fe0b17bac059575878e57af70482151cc2ab380
statements: 32
automated: 32
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 14 | 1. **Given** the implemented feature **When** its acceptance criterion applies — \| McpTransport is a plain Dart value object with 4 required fields (id, transportType, endpoint, authRequired) and a const constructor \| yes \| — **Then** the pinned regression suite confirms it. | A1 | automated |
| AC-2 | 15 | 2. **Given** the implemented feature **When** its acceptance criterion applies — \| Value equality holds when all 4 fields are identical; inequality is detected when any field differs \| yes \| — **Then** the pinned regression suite confirms it. | A2 | automated |
| AC-3 | 16 | 3. **Given** the implemented feature **When** its acceptance criterion applies — \| hashCode is consistent with == (equal instances share hashCode) \| yes \| — **Then** the pinned regression suite confirms it. | A3 | automated |
| AC-4 | 17 | 4. **Given** the implemented feature **When** its acceptance criterion applies — \| McpTransportService is abstract, mixes in Loggable and FailureHandler, declares current(NoParams) and count(NoParams) \| yes \| — **Then** the pinned regression suite confirms it. | A4 | automated |
| AC-5 | 18 | 5. **Given** the implemented feature **When** its acceptance criterion applies — \| McpTransportProvider implements McpTransportService and throws UnimplementedError for both methods \| yes \| — **Then** the pinned regression suite confirms it. | A5 | automated |
| AC-6 | 19 | 6. **Given** the implemented feature **When** its acceptance criterion applies — \| toString includes id, transportType, and endpoint \| yes \| — **Then** the pinned regression suite confirms it. | A6 | automated |
| AC-7 | 20 | 7. **Given** the implemented feature **When** its acceptance criterion applies — \| IoSseMcpTransport implements McpWire; close() is idempotent and sets isOpen=false \| yes \| — **Then** the pinned regression suite confirms it. | A7 | automated |
| AC-8 | 21 | 8. **Given** the implemented feature **When** its acceptance criterion applies — \| IoStdioMcpTransport implements McpWire; close() is idempotent and sets isOpen=false \| yes \| — **Then** the pinned regression suite confirms it. | A8 | automated |
| AC-9 | 22 | 9. **Given** the implemented feature **When** its acceptance criterion applies — \| Both transport stubs start with isOpen=false and open()/send() throw UnimplementedError \| yes \| — **Then** the pinned regression suite confirms it. | A9 | automated |
| AC-10 | 46 | 10. **Given** the feature implementation under its clean-architecture seams **When** McpTransport equality is value-based across all fields **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`). | A10 | automated |
| AC-11 | 47 | 11. **Given** the feature implementation under its clean-architecture seams **When** McpTransport inequality differs when a field changes **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`). | A11 | automated |
| AC-12 | 48 | 12. **Given** the feature implementation under its clean-architecture seams **When** McpTransport inequality detected per-field: id **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`). | A12 | automated |
| AC-13 | 49 | 13. **Given** the feature implementation under its clean-architecture seams **When** McpTransport inequality detected per-field: transportType **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`). | A13 | automated |
| AC-14 | 50 | 14. **Given** the feature implementation under its clean-architecture seams **When** McpTransport inequality detected per-field: endpoint **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`). | A14 | automated |
| AC-15 | 51 | 15. **Given** the feature implementation under its clean-architecture seams **When** McpTransport inequality detected per-field: authRequired **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`). | A15 | automated |
| AC-16 | 52 | 16. **Given** the feature implementation under its clean-architecture seams **When** toString includes id, transportType, and endpoint **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`). | A16 | automated |
| AC-17 | 53 | 17. **Given** the feature implementation under its clean-architecture seams **When** McpTransportProvider is a McpTransportService **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`). | A17 | automated |
| AC-18 | 54 | 18. **Given** the feature implementation under its clean-architecture seams **When** McpTransportProvider.current returns the active transport **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`). | A18 | automated |
| AC-19 | 55 | 19. **Given** the feature implementation under its clean-architecture seams **When** McpTransportProvider honors an injected active transport **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`). | A19 | automated |
| AC-20 | 56 | 20. **Given** the feature implementation under its clean-architecture seams **When** McpTransportProvider.count returns 1 **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`). | A20 | automated |
| AC-21 | 57 | 21. **Given** the feature implementation under its clean-architecture seams **When** starts with isOpen=false **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`). | A21 | automated |
| AC-22 | 58 | 22. **Given** the feature implementation under its clean-architecture seams **When** open() throws UnimplementedError **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`). | A22 | automated |
| AC-23 | 59 | 23. **Given** the feature implementation under its clean-architecture seams **When** send() throws UnimplementedError **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`). | A23 | automated |
| AC-24 | 60 | 24. **Given** the feature implementation under its clean-architecture seams **When** close() sets isOpen=false and is idempotent **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`). | A24 | automated |
| AC-25 | 61 | 25. **Given** the feature implementation under its clean-architecture seams **When** notifications is a broadcast stream **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`). | A25 | automated |
| AC-26 | 62 | 26. **Given** the feature implementation under its clean-architecture seams **When** accepts optional bearerToken **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`). | A26 | automated |
| AC-27 | 63 | 27. **Given** the feature implementation under its clean-architecture seams **When** starts with isOpen=false **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`). | A27 | automated |
| AC-28 | 64 | 28. **Given** the feature implementation under its clean-architecture seams **When** open() throws UnimplementedError **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`). | A28 | automated |
| AC-29 | 65 | 29. **Given** the feature implementation under its clean-architecture seams **When** send() throws UnimplementedError **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`). | A29 | automated |
| AC-30 | 66 | 30. **Given** the feature implementation under its clean-architecture seams **When** close() sets isOpen=false and is idempotent **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`). | A30 | automated |
| AC-31 | 67 | 31. **Given** the feature implementation under its clean-architecture seams **When** accepts empty args list **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`). | A31 | automated |
| AC-32 | 68 | 32. **Given** the feature implementation under its clean-architecture seams **When** accepts non-empty args list **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`). | A32 | automated |

