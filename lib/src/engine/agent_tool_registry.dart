/// Agent Tool Registry — implementation of ToolRegistry with namespace collision handling.
///
/// Provides deterministic prefixing:
/// - DDA tools: native namespace (no prefix)
/// - Generated tools: `gen:` prefix
/// - MCP tools: `mcp:<server_id>:` prefix
library;

import 'dart:async';

import 'tool_registry.dart';
import '../domain/entities/agent_tool/agent_tool.dart';
import '../domain/entities/enums/tool_source.dart';
import '../domain/entities/enums/risk_tier.dart';
import '../domain/entities/enums/execution_mode.dart';

/// Agent tool registry implementation.
class AgentToolRegistry implements ToolRegistry {
  AgentToolRegistry({int maxParallel = 10})
      : _collisionController = StreamController<NamespaceCollisionEvent>.broadcast();

  final Map<String, AgentTool> _tools = {};
  final StreamController<NamespaceCollisionEvent> _collisionController;

  @override
  Stream<NamespaceCollisionEvent> get onCollision => _collisionController.stream;

  @override
  Future<void> registerDdaTool(AgentTool tool) async {
    await _register(tool, ToolSource.dda, serverId: null);
  }

  @override
  Future<void> registerGeneratedTool(AgentTool tool) async {
    await _register(tool, ToolSource.generated, serverId: null);
  }

  @override
  Future<void> registerMcpTool(AgentTool tool, String serverId) async {
    await _register(tool, ToolSource.mcp, serverId: serverId);
  }

  Future<void> _register(AgentTool tool, ToolSource source, {String? serverId}) async {
    final prefix = _prefixForSource(source, serverId: serverId);
    final qualifiedName = '$prefix${tool.name}';

    // Check for collision
    if (_tools.containsKey(qualifiedName)) {
      final existing = _tools[qualifiedName]!;
      final existingSource = _sourceForName(existing.name);

      _collisionController.add(NamespaceCollisionEvent(
        toolName: tool.name,
        sources: [existingSource, source.name],
        resolution: 'prefix applied to non-native',
      ));

      // Keep the first registered (DDA wins for native namespace)
      if (source != ToolSource.dda) {
        return; // Don't overwrite native tool
      }
    }

    // Store with qualified name as key, but tool keeps original name
    _tools[qualifiedName] = tool;
  }

  @override
  Future<void> unregister(String qualifiedName) async {
    _tools.remove(qualifiedName);
  }

  @override
  Future<AgentTool?> resolve(String qualifiedName) async {
    // Try exact match first
    if (_tools.containsKey(qualifiedName)) {
      return _tools[qualifiedName];
    }

    // Try with each prefix
    for (final source in ToolSource.values) {
      final prefix = _prefixForSource(source, serverId: 'dummy');
      if (qualifiedName.startsWith(prefix)) {
        final name = qualifiedName.substring(prefix.length);
        final key = '$prefix$name';
        if (_tools.containsKey(key)) {
          return _tools[key];
        }
      }
    }

    return null;
  }

  @override
  Future<List<AgentTool>> list() async {
    return _tools.values.toList();
  }

  String _prefixForSource(ToolSource source, {String? serverId}) {
    switch (source) {
      case ToolSource.dda:
        return '';
      case ToolSource.generated:
        return 'gen:';
      case ToolSource.mcp:
        final id = serverId ?? 'unknown';
        return 'mcp:${id.substring(0, min(8, id.length))}:';
    }
  }

  String _sourceForName(String name) {
    if (name.startsWith('gen:')) return 'generated';
    if (name.startsWith('mcp:')) return 'mcp';
    return 'dda';
  }

  int min(int a, int b) => a < b ? a : b;

  void dispose() {
    _collisionController.close();
  }
}