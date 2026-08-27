# Implementation Plan: McpTransport sealed (in-proc/SSE/stdio)
**Branch**: `feat/specs-046-047-048-049` | **Date**: 2026-08-28

## Technical Context
- **Repo**: zuraffa_agent — clean-architecture providers/entities/services, engine layer, MCP transport, build_runner codegen, test harness (dart test + mocktail).
- **Pattern**: mirrors spec 033 (SteeringQueue + SteeringMessage): plain Dart value objects, no @Zorphy codegen, compiles without build_runner.
- **MCP Wire seam**: `lib/src/mcp/mcp_wire.dart` defines the abstract McpWire interface (open, close, send, notifications, isOpen). The SSE/stdio transports implement this seam.
- **Transport stubs**: `io_sse_mcp_transport.dart` and `io_stdio_mcp_transport.dart` are runtime-purity-allowlisted stubs — open() and send() throw UnimplementedError; close() sets isOpen=false and closes the notification stream.

## Summary
Hand-curate the `McpTransport` value object (R3 spec-exact) + `McpTransportService` + `McpTransportProvider`. Plus transport stub behavior tests.

## Phase 1 - Design
- **McpTransport** (value object): 4 fields, value equality across all of them.
- **Service** (`McpTransportService`): abstract, two NoParams-param methods.
- **Provider** (`McpTransportProvider`): concrete stub implementing `McpTransportService`.
- **IoSseMcpTransport**: implements McpWire, stub for SSE transport.
- **IoStdioMcpTransport**: implements McpWire, stub for stdio transport.

## Phase 2 - Tasks
See `tasks.md`.
