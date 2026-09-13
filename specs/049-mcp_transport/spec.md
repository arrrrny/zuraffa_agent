**Template Version**: `zuraffa-1.0`

# Feature Specification: McpTransport sealed (in-proc/SSE/stdio)

**Branch**: `feat/specs-046-047-048-049` | **Date**: 2026-08-28

## Summary
Sealed transport — in-proc (same-isolate), SSE+Bearer (reconnect, auth callback), stdio (subprocess pipe). One client interface, three transports (epic #3 §R3.3, issue #4 US3). This advances epic issue #4 (Tools & MCP). Pattern: hand-curated plain Dart value object (no @Zorphy), abstract service interface with NoParams parameters, concrete provider stub throwing UnimplementedError, regression tests for value equality + clean-arch layering.

## Acceptance Criteria

| id | criterion | verified |
|----|-----------|----------|
1. **Given** the implemented feature **When** its acceptance criterion applies — | McpTransport is a plain Dart value object with 4 required fields (id, transportType, endpoint, authRequired) and a const constructor | yes | — **Then** the pinned regression suite confirms it.
   **Type**: acceptance
2. **Given** the implemented feature **When** its acceptance criterion applies — | Value equality holds when all 4 fields are identical; inequality is detected when any field differs | yes | — **Then** the pinned regression suite confirms it.
   **Type**: acceptance
3. **Given** the implemented feature **When** its acceptance criterion applies — | hashCode is consistent with == (equal instances share hashCode) | yes | — **Then** the pinned regression suite confirms it.
   **Type**: acceptance
4. **Given** the implemented feature **When** its acceptance criterion applies — | McpTransportService is abstract, mixes in Loggable and FailureHandler, declares current(NoParams) and count(NoParams) | yes | — **Then** the pinned regression suite confirms it.
   **Type**: acceptance
5. **Given** the implemented feature **When** its acceptance criterion applies — | McpTransportProvider implements McpTransportService and throws UnimplementedError for both methods | yes | — **Then** the pinned regression suite confirms it.
   **Type**: acceptance
6. **Given** the implemented feature **When** its acceptance criterion applies — | toString includes id, transportType, and endpoint | yes | — **Then** the pinned regression suite confirms it.
   **Type**: acceptance
7. **Given** the implemented feature **When** its acceptance criterion applies — | IoSseMcpTransport implements McpWire; close() is idempotent and sets isOpen=false | yes | — **Then** the pinned regression suite confirms it.
   **Type**: acceptance
8. **Given** the implemented feature **When** its acceptance criterion applies — | IoStdioMcpTransport implements McpWire; close() is idempotent and sets isOpen=false | yes | — **Then** the pinned regression suite confirms it.
   **Type**: acceptance
9. **Given** the implemented feature **When** its acceptance criterion applies — | Both transport stubs start with isOpen=false and open()/send() throw UnimplementedError | yes | — **Then** the pinned regression suite confirms it.
   **Type**: acceptance

## Files
- `lib/src/domain/entities/mcp_transport/mcp_transport.dart` - `McpTransport` value object (4 fields; value-based equality).
- `lib/src/domain/services/mcp_transport_service.dart` - abstract `McpTransportService` (current(NoParams), count(NoParams)).
- `lib/src/data/providers/mcp_transport/mcp_transport_provider.dart` - concrete `McpTransportProvider` stub (UnimplementedError bodies).
- `lib/src/mcp/io_sse_mcp_transport.dart` - SSE transport stub implementing McpWire.
- `lib/src/mcp/io_stdio_mcp_transport.dart` - Stdio transport stub implementing McpWire.
- `test/data/providers/mcp_transport/mcp_transport_provider_test.dart` - regression tests (entity equality + clean-arch + toString + transport stubs).
- `specs/049-mcp_transport/{spec,plan,tasks}.md`.
- `specs/049-mcp_transport/tdd/{test-list,verification}.md`.

## Verification
- `dart pub get` clean
- `dart analyze` - No new issues
- `dart test` - All pre-existing + new tests pass

## Advances #4 (Tools & MCP)

## Acceptance Scenarios

> Derived verbatim from the feature's pinned regression suite.
> Behaviors are inherited-green: the cited tests pass unmodified in
> the repo suite (dart test, 1201 passing).
10. **Given** the feature implementation under its clean-architecture seams **When** McpTransport equality is value-based across all fields **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`).
   **Type**: acceptance
11. **Given** the feature implementation under its clean-architecture seams **When** McpTransport inequality differs when a field changes **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`).
   **Type**: acceptance
12. **Given** the feature implementation under its clean-architecture seams **When** McpTransport inequality detected per-field: id **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`).
   **Type**: acceptance
13. **Given** the feature implementation under its clean-architecture seams **When** McpTransport inequality detected per-field: transportType **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`).
   **Type**: acceptance
14. **Given** the feature implementation under its clean-architecture seams **When** McpTransport inequality detected per-field: endpoint **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`).
   **Type**: acceptance
15. **Given** the feature implementation under its clean-architecture seams **When** McpTransport inequality detected per-field: authRequired **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`).
   **Type**: acceptance
16. **Given** the feature implementation under its clean-architecture seams **When** toString includes id, transportType, and endpoint **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`).
   **Type**: acceptance
17. **Given** the feature implementation under its clean-architecture seams **When** McpTransportProvider is a McpTransportService **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`).
   **Type**: acceptance
18. **Given** the feature implementation under its clean-architecture seams **When** McpTransportProvider.current returns the active transport **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`).
   **Type**: acceptance
19. **Given** the feature implementation under its clean-architecture seams **When** McpTransportProvider honors an injected active transport **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`).
   **Type**: acceptance
20. **Given** the feature implementation under its clean-architecture seams **When** McpTransportProvider.count returns 1 **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`).
   **Type**: acceptance
21. **Given** the feature implementation under its clean-architecture seams **When** starts with isOpen=false **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`).
   **Type**: acceptance
22. **Given** the feature implementation under its clean-architecture seams **When** open() throws UnimplementedError **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`).
   **Type**: acceptance
23. **Given** the feature implementation under its clean-architecture seams **When** send() throws UnimplementedError **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`).
   **Type**: acceptance
24. **Given** the feature implementation under its clean-architecture seams **When** close() sets isOpen=false and is idempotent **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`).
   **Type**: acceptance
25. **Given** the feature implementation under its clean-architecture seams **When** notifications is a broadcast stream **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`).
   **Type**: acceptance
26. **Given** the feature implementation under its clean-architecture seams **When** accepts optional bearerToken **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`).
   **Type**: acceptance
27. **Given** the feature implementation under its clean-architecture seams **When** starts with isOpen=false **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`).
   **Type**: acceptance
28. **Given** the feature implementation under its clean-architecture seams **When** open() throws UnimplementedError **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`).
   **Type**: acceptance
29. **Given** the feature implementation under its clean-architecture seams **When** send() throws UnimplementedError **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`).
   **Type**: acceptance
30. **Given** the feature implementation under its clean-architecture seams **When** close() sets isOpen=false and is idempotent **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`).
   **Type**: acceptance
31. **Given** the feature implementation under its clean-architecture seams **When** accepts empty args list **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`).
   **Type**: acceptance
32. **Given** the feature implementation under its clean-architecture seams **When** accepts non-empty args list **Then** the pinned regression test passes (`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`).
   **Type**: acceptance
