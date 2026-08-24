# Implementation Plan: McpTransport sealed (in-proc/SSE/stdio)
**Branch**: `049-mcp_transport` | **Date**: 2026-08-24

## Summary
Hand-curate the `McpTransport` value object (R3 spec-exact) + `McpTransportService` + `McpTransportProvider`. Pattern mirrors spec 033 (SteeringQueue + SteeringMessage): plain Dart value objects, no @Zorphy codegen, compiles without build_runner.

## Phase 1 - Design
- **McpTransport** (value object): 4 fields, value equality across all of them.
- **Service** (`McpTransportService`): abstract, two NoParams-param methods - current(NoParams) returns the current snapshot, count(NoParams) returns the count.
- **Provider** (`McpTransportProvider`): concrete stub implementing `McpTransportService` with matching NoParams signatures; bodies throw UnimplementedError.

## Phase 2 - Tasks
See `tasks.md`.
