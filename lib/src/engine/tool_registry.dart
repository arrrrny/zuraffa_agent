/// Tool Registry — interface for registering and resolving agent tools.
///
/// Supports DDA, generated, and MCP tools with namespace collision handling.
library;

import '../domain/entities/agent_tool/agent_tool.dart';

/// Event emitted when namespace collision is detected.
class NamespaceCollisionEvent {
  const NamespaceCollisionEvent({
    required this.toolName,
    required this.sources,
    required this.resolution,
  });

  final String toolName;
  final List<String> sources;
  final String resolution;
}

/// Tool registry interface.
abstract class ToolRegistry {
  /// Register a DDA tool (native namespace, no prefix).
  Future<void> registerDdaTool(AgentTool tool);

  /// Register a generated tool (prefixed with 'gen:').
  Future<void> registerGeneratedTool(AgentTool tool);

  /// Register an MCP tool (prefixed with `mcp:<server_id>:`).
  Future<void> registerMcpTool(AgentTool tool, String serverId);

  /// Unregister a tool by its fully qualified name.
  Future<void> unregister(String qualifiedName);

  /// Resolve a tool by its qualified name (with or without prefix).
  Future<AgentTool?> resolve(String qualifiedName);

  /// List all registered tools.
  Future<List<AgentTool>> list();

  /// Stream of namespace collision events.
  Stream<NamespaceCollisionEvent> get onCollision;
}