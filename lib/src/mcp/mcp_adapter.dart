/// Thin MCP delegation layer (FR-006, SC-008, contracts/mcp-adapter.md).
///
/// pi-mcp owns MCP transport, listing, and calls; the wrapper contributes only
/// governance/telemetry metadata: tool-name prefixing (`mcp__<server>__<tool>`)
/// for governance lookup, risk-tier wiring (via [GovernancePolicy]), and a
/// telemetry tap. With no [McpDelegate] (pi-mcp absent) the adapter throws a
/// typed [McpUnavailableException] — it never ships a second MCP client.
library;

import '../ports/agent_telemetry_port.dart';

/// A tool exposed by an MCP server (pi-mcp's shape, mirrored minimally).
class McpTool {
  final String name;
  final String description;
  const McpTool(this.name, [this.description = '']);
}

/// The result of an MCP tool call.
class McpCallResult {
  final String output;
  final bool isError;
  const McpCallResult(this.output, {this.isError = false});
}

/// The pi-mcp surface the wrapper delegates to. Production adapters wrap
/// pi-mcp; tests use [InMemoryMcpDelegate].
abstract class McpDelegate {
  Future<List<McpTool>> listTools();
  Future<McpCallResult> callTool(String name, Map<String, Object?> args);
}

/// Thrown when pi-mcp is unavailable (SC-008).
class McpUnavailableException implements Exception {
  final String message;
  const McpUnavailableException(this.message);
  @override
  String toString() => 'McpUnavailableException: $message';
}

/// Pure-Dart in-memory [McpDelegate] (scripted pi-mcp).
class InMemoryMcpDelegate implements McpDelegate {
  final List<McpTool> tools;
  InMemoryMcpDelegate({this.tools = const []});

  @override
  Future<List<McpTool>> listTools() async => tools;

  @override
  Future<McpCallResult> callTool(
    String name,
    Map<String, Object?> args,
  ) async => McpCallResult('called $name with $args');
}

/// Delegates MCP listing/calls to pi-mcp and adds governance/telemetry taps.
class McpAdapter {
  final McpDelegate? _delegate;
  final AgentTelemetryPort _telemetry;

  McpAdapter({
    required McpDelegate? delegate,
    required AgentTelemetryPort telemetry,
  }) : _delegate = delegate,
       _telemetry = telemetry;

  /// The governance lookup name for a server tool: `mcp__<server>__<tool>`.
  static String prefix(String server, String tool) => 'mcp__${server}__$tool';

  Future<List<McpTool>> listTools() async {
    final delegate = _delegate;
    if (delegate == null) {
      _telemetry.recordEvent(
        const AgentTelemetryEvent(
          'mcp',
          attributes: {'outcome': 'mcpUnavailable'},
        ),
      );
      throw const McpUnavailableException('pi-mcp is unavailable');
    }
    final tools = await delegate.listTools();
    _telemetry.recordEvent(
      AgentTelemetryEvent(
        'mcp',
        attributes: {'outcome': 'listTools', 'count': tools.length},
      ),
    );
    return tools;
  }

  Future<McpCallResult> callTool(String name, Map<String, Object?> args) async {
    final delegate = _delegate;
    if (delegate == null) {
      _telemetry.recordEvent(
        const AgentTelemetryEvent(
          'mcp',
          attributes: {'outcome': 'mcpUnavailable'},
        ),
      );
      throw const McpUnavailableException('pi-mcp is unavailable');
    }
    final result = await delegate.callTool(name, args);
    _telemetry.recordEvent(
      AgentTelemetryEvent(
        'mcp',
        attributes: {
          'outcome': 'callTool',
          'tool': name,
          'isError': result.isError,
        },
      ),
    );
    return result;
  }
}
