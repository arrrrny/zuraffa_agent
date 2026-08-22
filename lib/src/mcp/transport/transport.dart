/// MCP Transport abstract interface.
library;

import 'sse_transport_config.dart';
import 'stdio_transport_config.dart';
import 'inproc_transport_config.dart';
import 'reconnect_policy.dart';
import 'restart_policy.dart';

/// MCP Transport abstract interface.
abstract class McpTransport {
  String get type;
  
  /// Connect to the transport
  Future<void> connect();
  
  /// Disconnect from the transport
  Future<void> disconnect();
  
  /// List available tools
  Future<List<McpTool>> listTools();
  
  /// Call a tool
  Future<McpToolResult> callTool(String name, Map<String, dynamic> arguments);
  
  /// Stream of tool list changes
  Stream<void> get onToolsChanged;
}

/// MCP Tool definition
class McpTool {
  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;
  
  McpTool({required this.name, required this.description, required this.inputSchema});
}

/// MCP Tool Result
class McpToolResult {
  final String content;
  final bool isError;
  final String? errorMessage;
  
  McpToolResult({required this.content, this.isError = false, this.errorMessage});
}