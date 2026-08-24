// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#4 (R3 - tools & mcp).
//
// ToolRegistry (single namespace) value object - spec-exact from epic #1 §R3 (issue #4).
// Pattern mirrors the SteeringMessage / SteeringQueue value objects
// (PR for spec 033): plain Dart, value equality across all fields,
// no @Zorphy codegen, compiles without build_runner.

/// ToolRegistry (single namespace) value object.
///
/// Single-namespace tool registry — DDA, generated, and remote-MCP tools all live behind one lookup (epic #3 §R3.1, issue #4 US1). The engine queries by name and gets back a typed AgentTool with JSON Schema.
class ToolRegistry {
  final String id;
  final List<String> toolNames;
  final int ddToolCount;
  final int generatedToolCount;
  final int mcpToolCount;

  const ToolRegistry({
    required this.id,
    required this.toolNames,
    required this.ddToolCount,
    required this.generatedToolCount,
    required this.mcpToolCount,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ToolRegistry &&
          runtimeType == other.runtimeType && id == other.id && toolNames == other.toolNames && ddToolCount == other.ddToolCount && generatedToolCount == other.generatedToolCount && mcpToolCount == other.mcpToolCount);

  @override
  int get hashCode => Object.hash(id, toolNames, ddToolCount, generatedToolCount, mcpToolCount);

  @override
  String toString() =>
      'ToolRegistry(id: $id, toolNames: $toolNames, ddToolCount: $ddToolCount)';
}
