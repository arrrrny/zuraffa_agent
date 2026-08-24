# Feature Specification: McpTransport sealed (in-proc/SSE/stdio)

**Branch**: `049-mcp_transport` | **Date**: 2026-08-24

## Summary
Sealed transport — in-proc (same-isolate), SSE+Bearer (reconnect, auth callback), stdio (subprocess pipe). One client interface, three transports (epic #3 §R3.3, issue #4 US3). This advances epic issue #4 (Tools & MCP). Pattern: hand-curated plain Dart value object (no @Zorphy), abstract service interface with NoParams parameters, concrete provider stub throwing UnimplementedError, regression tests for value equality + clean-arch layering.

## Files
- `lib/src/domain/entities/mcp_transport/mcp_transport.dart` - `McpTransport` value object (4 fields; value-based equality).
- `lib/src/domain/services/mcp_transport_service.dart` - abstract `McpTransportService` (current(NoParams), count(NoParams)).
- `lib/src/data/providers/mcp_transport/mcp_transport_provider.dart` - concrete `McpTransportProvider` stub (UnimplementedError bodies).
- `test/data/providers/mcp_transport/mcp_transport_provider_test.dart` - 5 regression tests (2 entity equality + 3 clean-arch).
- `specs/049-mcp_transport/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` - No issues
- `dart test` - All pre-existing + 5 new tests pass

## Advances #4 (Tools & MCP)
