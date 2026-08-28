# Feature Specification: McpTransport sealed (in-proc/SSE/stdio)

**Branch**: `feat/specs-046-047-048-049` | **Date**: 2026-08-28

## Summary
Sealed transport — in-proc (same-isolate), SSE+Bearer (reconnect, auth callback), stdio (subprocess pipe). One client interface, three transports (epic #3 §R3.3, issue #4 US3). This advances epic issue #4 (Tools & MCP). Pattern: hand-curated plain Dart value object (no @Zorphy), abstract service interface with NoParams parameters, concrete provider stub throwing UnimplementedError, regression tests for value equality + clean-arch layering.

## Acceptance Criteria

| id | criterion | verified |
|----|-----------|----------|
| AC-1 | McpTransport is a plain Dart value object with 4 required fields (id, transportType, endpoint, authRequired) and a const constructor | yes |
| AC-2 | Value equality holds when all 4 fields are identical; inequality is detected when any field differs | yes |
| AC-3 | hashCode is consistent with == (equal instances share hashCode) | yes |
| AC-4 | McpTransportService is abstract, mixes in Loggable and FailureHandler, declares current(NoParams) and count(NoParams) | yes |
| AC-5 | McpTransportProvider implements McpTransportService and throws UnimplementedError for both methods | yes |
| AC-6 | toString includes id, transportType, and endpoint | yes |
| AC-7 | IoSseMcpTransport implements McpWire; close() is idempotent and sets isOpen=false | yes |
| AC-8 | IoStdioMcpTransport implements McpWire; close() is idempotent and sets isOpen=false | yes |
| AC-9 | Both transport stubs start with isOpen=false and open()/send() throw UnimplementedError | yes |

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
