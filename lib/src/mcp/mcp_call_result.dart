// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#15 (spec 015-mcp-client).
//
// McpCallResult sealed family — the outcome of invoking an MCP tool.
// Pairs with ToolCallStarted/ToolCallCompleted engine events (issues
// #22/#21): the engine correlates via callId and surfaces the result
// through the dispatcher.
//
// Pattern: sealed class declared in this library with `final class`
// subtypes, same shape as the hand-curated EngineEvent sealed library
// (lib/src/engine/events/engine_event.dart). Compiles without running
// build_runner.

/// Result of invoking an MCP tool — sealed union of [McpCallOk] and
/// [McpCallError].
///
/// The engine never receives a thrown exception from `McpClient.callTool`:
/// failures surface as [McpCallError] so the dispatcher can map them to
/// typed `ToolDispatchResult` records without try/catch noise.
sealed class McpCallResult {
  const McpCallResult();
}

/// Successful tool invocation — the result payload is a JSON-serializable
/// map (the MCP spec's `content` block).
final class McpCallOk extends McpCallResult {
  /// The tool's structured output. Keys are tool-defined; values are
  /// JSON-serializable (string, number, bool, list, map).
  final Map<String, dynamic> result;

  const McpCallOk(this.result);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is McpCallOk && runtimeType == other.runtimeType && _mapEq(result, other.result));

  static bool _mapEq(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(result.values);

  @override
  String toString() => 'McpCallOk(${result.length} keys)';
}

/// Failed tool invocation — short machine code + human-readable message.
///
/// Common codes (informative — the MCP server is the source of truth):
/// - `tool-not-found` — the server doesn't know this tool name.
/// - `invalid-params` — the params didn't validate against the schema.
/// - `transport-error` — the underlying wire failed mid-call.
/// - `timeout` — the call exceeded the configured deadline.
final class McpCallError extends McpCallResult {
  final String code;
  final String message;

  const McpCallError({required this.code, required this.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is McpCallError &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          message == other.message);

  @override
  int get hashCode => Object.hash(code, message);

  @override
  String toString() => 'McpCallError($code: $message)';
}
