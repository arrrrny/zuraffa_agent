/// InProc Transport — direct registry calls, zero IPC.
library;

import 'dart:convert';

import 'transport.dart';
import '../../engine/tool_registry.dart';
import '../../domain/entities/agent_tool/agent_tool.dart';

/// InProc Transport — MCP via direct registry calls (zero IPC).
class InProcTransport implements McpTransport {
  @override
  final String type = 'inproc';

  final ToolRegistry _registry;

  InProcTransport(this._registry);

  @override
  Future<void> connect() async {
    // No connection needed for in-proc
  }

  @override
  Future<void> disconnect() async {
    // No cleanup needed
  }

  @override
  Future<List<McpTool>> listTools() async {
    final tools = await _registry.list();
    return tools.map((tool) => McpTool(
      name: tool.name,
      description: tool.description,
      inputSchema: Map<String, dynamic>.from(tool.inputSchema),
    )).toList();
  }

  @override
  Future<McpToolResult> callTool(String name, Map<String, dynamic> arguments) async {
    final tool = await _registry.resolve(name);
    if (tool == null) {
      return McpToolResult(
        content: '',
        isError: true,
        errorMessage: 'Tool not found: $name',
      );
    }
    
    // For in-proc, we'd execute the tool directly
    // This is a placeholder - actual execution depends on the tool source
    return McpToolResult(
      content: jsonEncode({'tool': name, 'status': 'executed', 'arguments': arguments}),
      isError: false,
    );
  }

  @override
  Stream<void> get onToolsChanged => const Stream.empty();
}