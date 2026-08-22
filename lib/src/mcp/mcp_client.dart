/// MCP Client — facade for MCP protocol interactions.
///
/// Provides transport abstraction, auto-reconnect, and tool listing cache.
library;

import 'dart:async';

import 'transport/transport.dart';
import 'auth_callback.dart';
import '../engine/tool_registry.dart';
import '../domain/entities/agent_tool/agent_tool.dart';
import '../domain/entities/enums/risk_tier.dart';
import '../domain/entities/enums/execution_mode.dart';
import '../domain/entities/enums/tool_source.dart';

/// Main MCP client facade.
class McpClient {
  McpClient({
    required this.transport,
    this.onToolsChanged,
  });

  final McpTransport transport;
  final Stream<void>? onToolsChanged;

  List<McpTool>? _cachedTools;

  /// Initialize connection and fetch tool list.
  Future<void> connect() async {
    await transport.connect();
    await _refreshToolList();
  }

  /// Disconnect from the transport.
  Future<void> disconnect() async {
    await transport.disconnect();
  }

  /// List available tools (uses cache if available).
  Future<List<McpTool>> listTools() async {
    if (_cachedTools == null) {
      await _refreshToolList();
    }
    return _cachedTools ?? [];
  }

  /// Call a tool.
  Future<McpToolResult> callTool(String name, Map<String, dynamic> arguments) async {
    return transport.callTool(name, arguments);
  }

  /// Register MCP tools into the provided tool registry.
  Future<void> registerTools(ToolRegistry registry, String serverId) async {
    final tools = await listTools();
    for (final tool in tools) {
      final agentTool = AgentTool(
        name: tool.name,
        description: tool.description,
        inputSchema: tool.inputSchema,
        riskTier: RiskTier.safe,
        executionMode: ExecutionMode.sequential,
        source: ToolSource.mcp,
        transportBinding: serverId,
      );
      await registry.registerMcpTool(agentTool, serverId);
    }
  }

  Future<void> _refreshToolList() async {
    _cachedTools = await transport.listTools();
  }
}