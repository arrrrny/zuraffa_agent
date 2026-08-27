// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#15 (spec 015-mcp-client).
//
// InProcMcpClient — the in-process transport (zero IPC). Tools are
// registered as local Dart callbacks; the MCP protocol shape (list /
// call) is preserved so the engine consumes the same McpClient
// interface regardless of transport.
//
// Spec 015 SC-001: "In-proc round-trip works with zero serialization."
// The implementation asserts object identity of the callback's return
// value — if serialization is ever introduced, the test
// (test/mcp/in_proc_mcp_client_test.dart) breaks immediately.

import 'dart:async';

import '../domain/entities/mcp_transport/mcp_transport.dart';
import 'mcp_call_result.dart';
import 'mcp_client.dart';
import 'mcp_tool_descriptor.dart';

/// Callback signature for an in-process MCP tool implementation.
typedef InProcMcpTool = Future<Map<String, dynamic>> Function(
  Map<String, dynamic> arguments,
);

/// In-process MCP client — local callbacks, zero IPC.
///
/// Construction:
///   ```dart
///   final client = InProcMcpClient(
///     transport: McpTransport(id: 'in-proc-1', transportType: 'in-proc',
///                              endpoint: 'local', authRequired: false),
///   );
///   client.registerTool(
///     descriptor: McpToolDescriptor(name: 'fs.read', description: '...'),
///     callback: (args) async => {'content': '...'},
///   );
///   await client.connect();
///   ```
class InProcMcpClient implements McpClient {
  @override
  final McpTransport transport;

  final Map<String, _RegisteredTool> _tools = {};
  final StreamController<void> _toolsChangedController =
      StreamController<void>.broadcast();

  McpClientState _state = McpClientState.disconnected;

  InProcMcpClient({required this.transport});

  /// Register a local tool under its descriptor's [McpToolDescriptor.name].
  /// Throws [ArgumentError] if a tool with the same name is already
  /// registered.
  void registerTool({
    required McpToolDescriptor descriptor,
    required InProcMcpTool callback,
  }) {
    if (_tools.containsKey(descriptor.name)) {
      throw ArgumentError(
        'InProcMcpClient: tool already registered: ${descriptor.name}',
      );
    }
    _tools[descriptor.name] = _RegisteredTool(descriptor, callback);
    // Only fire onToolsChanged if the client is connected —
    // registering before connect() is the common case and shouldn't
    // spam consumers.
    if (_state == McpClientState.connected) {
      _toolsChangedController.add(null);
    }
  }

  /// Unregister a tool by name. No-op if not registered.
  void unregisterTool(String name) {
    if (_tools.remove(name) != null && _state == McpClientState.connected) {
      _toolsChangedController.add(null);
    }
  }

  @override
  Future<void> connect() async {
    if (_state == McpClientState.connected) return;
    _state = McpClientState.connecting;
    // In-proc has no transport to open — flip to connected immediately.
    _state = McpClientState.connected;
  }

  @override
  Future<void> disconnect() async {
    _state = McpClientState.disconnected;
    await _toolsChangedController.close();
  }

  @override
  Future<List<McpToolDescriptor>> listTools() async {
    if (_state != McpClientState.connected) {
      throw StateError(
        'InProcMcpClient.listTools called in state $_state',
      );
    }
    // Return a snapshot — callers may mutate the returned list without
    // affecting the client's internal state.
    return [for (final t in _tools.values) t.descriptor];
  }

  @override
  Future<McpCallResult> callTool(
    String name,
    Map<String, dynamic> arguments,
  ) async {
    if (_state != McpClientState.connected) {
      return McpCallError(
        code: 'client-not-connected',
        message: 'InProcMcpClient.callTool in state $_state',
      );
    }
    final tool = _tools[name];
    if (tool == null) {
      return McpCallError(
        code: 'tool-not-found',
        message: 'InProcMcpClient: no tool registered as "$name"',
      );
    }
    try {
      final result = await tool.callback(arguments);
      return McpCallOk(result);
    } catch (e) {
      return McpCallError(
        code: 'tool-threw',
        message: 'InProcMcpClient: tool "$name" threw: $e',
      );
    }
  }

  @override
  Stream<void> get onToolsChanged => _toolsChangedController.stream;

  @override
  McpClientState get state => _state;
}

class _RegisteredTool {
  final McpToolDescriptor descriptor;
  final InProcMcpTool callback;
  const _RegisteredTool(this.descriptor, this.callback);
}
