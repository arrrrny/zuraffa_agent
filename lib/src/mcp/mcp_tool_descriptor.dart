// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#15 (spec 015-mcp-client).
//
// McpToolDescriptor value object — the static metadata an MCP server
// advertises for one of its tools. Mirrors the shape of AgentTool's
// declaration side (id + description + paramsSchema) so the engine
// ToolRegistry adapter (lib/src/mcp/mcp_tool_adapter.dart) can lift
// an MCP tool into an AgentTool without shape translation.
//
// Pattern: plain Dart value object (no @Zorphy annotation), same as
// the existing McpTransport / AgentTool value objects — compiles
// without running build_runner.

/// MCP tool descriptor — the static metadata an MCP server advertises.
///
/// Fields:
/// - [name]: the tool name as the MCP server reports it (e.g.
///   `"fs.read"`). Namespaced into the engine ToolRegistry as
///   `mcp:<serverId>:<name>` by `McpToolAdapter`.
/// - [description]: human-readable description surfaced in
///   tool-selection prompts to the model.
/// - [paramsSchema]: optional JSON Schema for typed-params validation
///   at dispatch. Null when the tool takes no params.
class McpToolDescriptor {
  final String name;
  final String description;
  final Map<String, dynamic>? paramsSchema;

  const McpToolDescriptor({
    required this.name,
    required this.description,
    this.paramsSchema,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is McpToolDescriptor &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          description == other.description &&
          _mapEq(paramsSchema, other.paramsSchema));

  static bool _mapEq(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == null && b == null;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (!_deepEq(a[key], b[key])) return false;
    }
    return true;
  }

  static bool _deepEq(Object? a, Object? b) {
    if (identical(a, b)) return true;
    if (a is Map && b is Map) {
      return _mapEq(a as Map<String, dynamic>?, b as Map<String, dynamic>?);
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_deepEq(a[i], b[i])) return false;
      }
      return true;
    }
    return a == b;
  }

  @override
  int get hashCode => Object.hash(name, description, paramsSchema);

  @override
  String toString() =>
      'McpToolDescriptor(name: $name, description: ${description.length > 40 ? "${description.substring(0, 40)}…" : description}, paramsSchema: ${paramsSchema == null ? "null" : "present"})';
}
