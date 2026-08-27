// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#15 (spec 015-mcp-client).
//
// McpClient interface — the runtime surface the engine consumes to
// connect to an MCP server, list its tools, invoke a tool, and react
// to server-side tool-list changes.
//
// Three implementations ship in this PR:
//   - InProcMcpClient   — local callbacks, zero IPC (spec SC-001).
//   - SseMcpClient      — delegates to an McpWire seam; real SSE lives
//                          in io_sse_mcp_transport.dart (purity allowlist).
//   - StdioMcpClient    — same shape, bounded retries for subprocess
//                          crashes; real stdio in io_stdio_mcp_transport.dart.
//
// Pattern: abstract interface only — no dart:io, no implementation.
// Mirrors lib/src/llm/llm_client.dart.

import '../domain/entities/mcp_transport/mcp_transport.dart';
import 'mcp_call_result.dart';
import 'mcp_tool_descriptor.dart';

/// State machine for an [McpClient].
///
/// - [disconnected] — initial state; never connected or after [McpClient.disconnect].
/// - [connecting] — [McpClient.connect] in flight.
/// - [connected] — connected and operational.
/// - [reconnecting] — transport dropped; reconnect backoff in progress.
/// - [failed] — reconnect policy exhausted; manual intervention required.
enum McpClientState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

/// The MCP client surface the engine consumes.
///
/// Lifecycle:
///   1. `connect()` — opens the transport; transitions to [McpClientState.connected]
///      on success or [McpClientState.failed] on terminal failure.
///   2. `listTools()` — returns the server's advertised tool descriptors.
///      May be cached by a [ToolListingCache] wrapper.
///   3. `callTool(name, args)` — invokes one tool; returns
///      [McpCallOk] on success or [McpCallError] on failure.
///   4. `onToolsChanged` — fires when the server reports a tools-changed
///      notification; consumers (e.g. [McpToolAdapter]) re-list and
///      re-surface into the engine ToolRegistry.
///   5. `disconnect()` — closes the transport; transitions to
///      [McpClientState.disconnected].
abstract class McpClient {
  /// The transport configuration this client was constructed against.
  McpTransport get transport;

  /// Open the transport. Idempotent: calling `connect()` on an already
  /// connected client is a no-op.
  Future<void> connect();

  /// Close the transport. Idempotent. Cancels any in-flight
  /// reconnect attempts.
  Future<void> disconnect();

  /// List the server's advertised tool descriptors.
  ///
  /// May throw on transport failure; consumers should catch and surface
  /// as a typed error (the dispatcher maps to `ToolDispatchResult`).
  Future<List<McpToolDescriptor>> listTools();

  /// Invoke a tool by name with the given arguments.
  ///
  /// Returns [McpCallOk] on success or [McpCallError] on failure; never
  /// throws — failures are surfaced as values so the dispatcher doesn't
  /// need a try/catch around every call.
  Future<McpCallResult> callTool(
    String name,
    Map<String, dynamic> arguments,
  );

  /// Stream that fires when the server reports a tools-changed
  /// notification. Consumers (e.g. [McpToolAdapter]) re-list and
  /// re-surface into the engine ToolRegistry.
  Stream<void> get onToolsChanged;

  /// Current client state — observed by the engine for diagnostics
  /// and by [McpToolAdapter] to skip registry mutations while the
  /// client is [McpClientState.reconnecting].
  McpClientState get state;
}
