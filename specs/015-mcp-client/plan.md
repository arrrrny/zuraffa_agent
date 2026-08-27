# Implementation Plan: MCP Client

**Branch**: `feat/specs-015-022-023-024` | **Spec**: [spec.md](./spec.md)

## Summary

Author the MCP (Model Context Protocol) client runtime for zuraffa_agent — connect, discover/list tools, invoke tools, surface them into the agent tool registry, and recover from transport failures. Built on top of the existing `McpTransport` value object (lib/src/domain/entities/mcp_transport/mcp_transport.dart) and the `McpTransportService` interface, this PR adds a pure-Dart `lib/src/mcp/` runtime layer that implements the protocol seam for three transport families (in-proc, SSE+Bearer, stdio) while respecting the constitution's runtime-purity gate (no `dart:io` outside the allowlisted I/O adapters).

## Technical Context

- **Language/Version**: Dart 3.13.x (`sdk: ^3.8.0`).
- **Package**: `zuraffa_agent` — pure Dart package (no Flutter SDK required).
- **Primary dependencies**:
  - `package:zuraffa/zuraffa.dart` — `Loggable`, `FailureHandler`, `NoParams` (already used by `McpTransportService`).
  - `package:zuraffa_agent/src/engine/tool_registry.dart` — `ToolRegistry` interface (consumer of surfaced MCP tools).
  - `package:zuraffa_agent/src/domain/entities/agent_tool/agent_tool.dart` — `AgentTool`, `RiskTier`, `ExecutionMode` (the tool-shape the registry accepts).
- **Storage**: None — the MCP client runtime is in-memory; persistence of the transport config is the existing `McpTransport` value object's concern (already shipped via `McpTransportProvider`).
- **Testing**: `dart test` (package:test). Fake transports — no real network in tests (constitution: fixtures only).
- **Constraints**:
  - MUST NOT import `dart:io` outside the allowlisted I/O-adapter files in `.github/workflows/pipeline.yml`. New I/O adapters added by this PR (`io_sse_mcp_transport.dart`, `io_stdio_mcp_transport.dart`) MUST be added to the allowlist with a justification comment.
  - MUST NOT regress 529 pre-existing tests.
  - MUST mirror the existing `lib/src/llm/` pattern: pure interface in `lib/src/mcp/`, IO-segregated concrete adapter in a sibling `io_*.dart` file.

## Constitution Check

- **Spec-003 (tools-and-mcp)** — defines the tool/MCP surface this client implements. ✓
- **Spec-002 (engine-core-loop)** — the engine loop will consume `McpClient` once a concrete dispatcher lands. The interface ships here; the loop wiring is spec-002 work.
- **Runtime purity (VII)** — `dart:io` confined to the allowlisted adapters; no engine runtime file imports `dart:io`. New adapters are added to the allowlist in `.github/workflows/pipeline.yml` with justification.
- **CLI-built only (I)** — the new `lib/src/mcp/` files are hand-curated (same pattern as the existing `lib/src/llm/` and the hand-curated `EngineEvent` library). zfa is not yet aware of MCP-client shape; this PR ships the canonical hand-curated implementation until zfa ships a matching generator.

## Project Structure

```text
lib/src/mcp/
├── mcp_client.dart                 # McpClient interface — connect / disconnect / listTools / callTool / onToolsChanged
├── mcp_tool_descriptor.dart        # McpToolDescriptor value object — name, description, paramsSchema
├── mcp_call_result.dart            # McpCallResult sealed (ok | error) — value object
├── mcp_wire.dart                   # McpWire interface (transport seam) — pure; fakes injectable in tests
├── mcp_reconnect_policy.dart       # Exponential-backoff-with-jitter reconnect policy — pure, injected clock for tests
├── in_proc_mcp_client.dart         # In-proc implementation — local tool callbacks, zero IPC
├── sse_mcp_client.dart              # SSE+Bearer implementation — uses McpWire seam (real SSE lives in io_sse_mcp_transport.dart)
├── stdio_mcp_client.dart            # stdio implementation — uses McpWire seam (real stdio lives in io_stdio_mcp_transport.dart)
├── tool_listing_cache.dart          # Pure cache — invalidation on tools-changed notification
├── mcp_tool_adapter.dart            # Adapter that surfaces MCP tools into the engine ToolRegistry
└── io_*.dart                        # IO-segregated adapters (allowlisted in pipeline.yml)

test/mcp/
├── in_proc_mcp_client_test.dart
├── tool_listing_cache_test.dart
├── mcp_reconnect_policy_test.dart
├── sse_mcp_client_test.dart          # Uses a fake McpWire — no real network
├── stdio_mcp_client_test.dart        # Uses a fake McpWire — no real subprocess
└── mcp_tool_adapter_test.dart        # Verifies tools surface into a fake ToolRegistry
```

## Phase 1 — Design

### McpClient interface (pure, no dart:io)

```dart
// lib/src/mcp/mcp_client.dart
abstract class McpClient {
  McpTransport get transport;
  Future<void> connect();
  Future<void> disconnect();
  Future<List<McpToolDescriptor>> listTools();
  Future<McpCallResult> callTool(String name, Map<String, dynamic> arguments);
  Stream<void> get onToolsChanged; // fires when the server reports a tools-changed notification
  McpClientState get state;
}

enum McpClientState { disconnected, connecting, connected, reconnecting, failed }
```

### McpWire seam (transport abstraction — pure)

```dart
// lib/src/mcp/mcp_wire.dart
abstract class McpWire {
  Future<void> open();
  Future<void> close();
  Future<McpWireResponse> send(McpWireRequest request);
  Stream<McpWireNotification> get notifications;
}

sealed class McpWireRequest  { /* list_tools, call_tool, ... */ }
sealed class McpWireResponse { /* ok, error */ }
sealed class McpWireNotification { /* tools_changed, ... */ }
```

### In-proc client (fully functional — local callbacks)

The in-proc client registers local Dart callbacks as MCP tools. `listTools`
returns the registered descriptors; `callTool` invokes the callback and wraps
the result. Zero IPC, zero serialization — satisfies SC-001.

### SSE + stdio clients (delegating to McpWire seam)

Both use the same `McpWire` abstraction; the difference is the concrete IO
adapter that fulfills the seam. The IO adapters (`io_sse_mcp_transport.dart`,
`io_stdio_mcp_transport.dart`) live in `lib/src/mcp/` and are added to the
purity allowlist. Reconnect logic is centralized in `McpReconnectPolicy` and
unit-tested with an injected clock (no real wall-time in tests).

### ToolListingCache (pure)

A pure-Dart LRU-style cache that wraps `listTools()` results and is
invalidated by `onToolsChanged` notifications. Exposes `getOrRefresh()` and
`invalidate()`. Bounded by a configurable max-age (default 60s) AND by
explicit invalidation.

### McpToolAdapter (surface into engine ToolRegistry)

Wraps an `McpClient`, listens for `onToolsChanged`, and registers/unregisters
MCP tools into the engine's `ToolRegistry` interface via
`registerMcpTool(AgentTool, serverId)` and `unregister(qualifiedName)`. Tools
are namespaced as `mcp:<serverId>:<toolName>` per the registry contract.

## Phase 2 — Tasks

See `tasks.md`.

## Phase 3 — TDD

See `tdd/test-list.md` and `tdd/verification.md`.
