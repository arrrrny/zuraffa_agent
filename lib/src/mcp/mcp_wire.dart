// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#15 (spec 015-mcp-client).
//
// McpWire — the transport seam abstracted away from the MCP client
// implementations. Lets the SSE/stdio clients be unit-tested with a
// fake wire (no real network / subprocess in tests, per the
// constitution's fixtures-only rule).
//
// Pattern mirrors lib/src/llm/llm_transport.dart: a pure seam interface
// whose concrete IO adapter lives in a sibling `io_*.dart` file that is
// on the pipeline purity allowlist.

/// Transport seam for the MCP client runtime.
///
/// Implemented by:
///   - `IoSseMcpTransport`   — real SSE over dart:io HttpClient
///                              (lib/src/mcp/io_sse_mcp_transport.dart).
///   - `IoStdioMcpTransport` — real stdio over dart:io Process
///                              (lib/src/mcp/io_stdio_mcp_transport.dart).
///   - Test fakes              — see test/mcp/*_test.dart.
///
/// The seam is intentionally minimal: `send` for request/response RPC,
/// `notifications` for server-pushed events. Reconnect / auth-callback
/// rotation lives on the MCP client, not on the wire — the wire is a
/// stateless transport.
abstract class McpWire {
  /// Open the transport. Must be idempotent.
  Future<void> open();

  /// Close the transport. Must be idempotent.
  Future<void> close();

  /// Send a request and await the matching response.
  Future<McpWireResponse> send(McpWireRequest request);

  /// Server-pushed notifications stream. The wire emits
  /// [McpWireNotificationToolsChanged] when the server reports a
  /// tools-changed notification; other notification subtypes may be
  /// added later.
  Stream<McpWireNotification> get notifications;

  /// True once [open] has succeeded and [close] has not been called
  /// since. Used by the reconnect policy to detect drops.
  bool get isOpen;
}

/// Request family — one per MCP RPC method supported by this client.
sealed class McpWireRequest {
  const McpWireRequest();
}

/// List the server's advertised tools.
final class McpWireRequestListTools extends McpWireRequest {
  const McpWireRequestListTools();
}

/// Invoke a tool by name with the given arguments.
final class McpWireRequestCallTool extends McpWireRequest {
  final String name;
  final Map<String, dynamic> arguments;
  const McpWireRequestCallTool({required this.name, required this.arguments});
}

/// Response family — sealed union of [McpWireResponseOk] and
/// [McpWireResponseError].
sealed class McpWireResponse {
  const McpWireResponse();
}

/// Successful response — payload is a JSON-serializable map.
final class McpWireResponseOk extends McpWireResponse {
  final Map<String, dynamic> payload;
  const McpWireResponseOk(this.payload);
}

/// Error response — short machine code + human-readable message.
final class McpWireResponseError extends McpWireResponse {
  final String code;
  final String message;
  const McpWireResponseError({required this.code, required this.message});
}

/// Notification family — server-pushed events.
sealed class McpWireNotification {
  const McpWireNotification();
}

/// The server reports the tool list changed; consumers should re-list.
final class McpWireNotificationToolsChanged extends McpWireNotification {
  const McpWireNotificationToolsChanged();
}
