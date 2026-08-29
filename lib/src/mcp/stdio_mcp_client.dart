// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#15 (spec 015-mcp-client).
//
// StdioMcpClient — the stdio MCP transport. Same shape as SseMcpClient
// but with the stdio reconnect policy (Spec 015 SC-003: restart within
// 10s). Delegates to an [McpWire] seam; the real stdio adapter lives
// in lib/src/mcp/io_stdio_mcp_transport.dart (purity allowlisted).
//
// No bearer token / auth callback — stdio is local IPC, auth is the
// OS process boundary.

import 'dart:async';

import '../domain/entities/mcp_transport/mcp_transport.dart';
import 'mcp_call_result.dart';
import 'mcp_client.dart';
import 'mcp_reconnect_policy.dart';
import 'mcp_tool_descriptor.dart';
import 'mcp_wire.dart';

/// Factory that builds a fresh [McpWire] for stdio. The stdio client
/// uses this to rebuild the wire when the subprocess crashes.
typedef McpStdioWireFactory = McpWire Function();

/// stdio MCP client.
class StdioMcpClient implements McpClient {
  @override
  final McpTransport transport;

  final McpStdioWireFactory _wireFactory;
  final McpReconnectPolicy _reconnect;

  McpWire? _wire;
  StreamSubscription<McpWireNotification>? _notifSub;
  final StreamController<void> _toolsChangedController =
      StreamController<void>.broadcast();
  final StreamController<void> _reconnectedController =
      StreamController<void>.broadcast();
  McpClientState _state = McpClientState.disconnected;
  DateTime? _lastStateChangeAt;

  void _setState(McpClientState next) {
    _state = next;
    _lastStateChangeAt = _clock();
  }

  StdioMcpClient({
    required this.transport,
    required McpStdioWireFactory wireFactory,
    McpReconnectPolicy? reconnectPolicy,
    required McpClock now,
    required McpDelay delay,
  })  : _wireFactory = wireFactory,
        _reconnect = reconnectPolicy ??
            McpReconnectPolicy(
              config: McpReconnectPolicyConfig.stdio,
              delay: delay,
            ),
        _clock = now;

  final McpClock _clock;

  /// When the client last transitioned state — diagnostic surface
  /// for downstream consumers (engine loop, metrics). Null until
  /// the first state transition.
  DateTime? get lastStateChangeAt => _lastStateChangeAt;

  @override
  Future<void> connect() async {
    if (_state == McpClientState.connected) return;
    _setState(McpClientState.connecting);
    try {
      _wire = _wireFactory();
      await _wire!.open();
      _notifSub = _wire!.notifications
          .where((n) => n is McpWireNotificationToolsChanged)
          .listen((_) => _toolsChangedController.add(null));
      _setState(McpClientState.connected);
      _reconnect.reset();
    } catch (e) {
      _setState(McpClientState.failed);
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    _setState(McpClientState.disconnected);
    await _notifSub?.cancel();
    _notifSub = null;
    await _wire?.close();
    _wire = null;
    await _toolsChangedController.close();
    await _reconnectedController.close();
  }

  @override
  Future<List<McpToolDescriptor>> listTools() async {
    if (_state != McpClientState.connected || _wire == null) {
      throw StateError('StdioMcpClient.listTools called in state $_state');
    }
    final resp = await _callWithReconnect(
      const McpWireRequestListTools(),
    );
    if (resp is! McpWireResponseOk) {
      final err = resp as McpWireResponseError;
      throw StateError('StdioMcpClient.listTools: ${err.code}: ${err.message}');
    }
    final payload = resp.payload;
    final toolsRaw = payload['tools'];
    if (toolsRaw is! List) {
      return const [];
    }
    return [
      for (final t in toolsRaw)
        if (t is Map<String, dynamic>)
          McpToolDescriptor(
            name: t['name'] as String? ?? '',
            description: t['description'] as String? ?? '',
            paramsSchema: t['paramsSchema'] as Map<String, dynamic>?,
          ),
    ];
  }

  @override
  Future<McpCallResult> callTool(
    String name,
    Map<String, dynamic> arguments,
  ) async {
    if (_state != McpClientState.connected || _wire == null) {
      return McpCallError(
        code: 'client-not-connected',
        message: 'StdioMcpClient.callTool in state $_state',
      );
    }
    try {
      final resp = await _callWithReconnect(
        McpWireRequestCallTool(name: name, arguments: arguments),
      );
      return switch (resp) {
        McpWireResponseOk(:final payload) => McpCallOk(payload),
        McpWireResponseError(:final code, :final message) =>
          McpCallError(code: code, message: message),
      };
    } catch (e) {
      return McpCallError(
        code: 'transport-error',
        message: 'StdioMcpClient.callTool($name) threw: $e',
      );
    }
  }

  Future<McpWireResponse> _callWithReconnect(McpWireRequest req) async {
    while (true) {
      try {
        final resp = await _wire!.send(req);
        // Only reset the policy after a successful send — `wire.open()`
        // succeeding doesn't guarantee `wire.send()` will.
        _reconnect.reset();
        return resp;
      } catch (e) {
        if (_reconnect.exhausted) {
          _setState(McpClientState.failed);
          rethrow;
        }
        _setState(McpClientState.reconnecting);
        await _reconnect.nextBackoff();
        _wire = _wireFactory();
        await _wire!.open();
        _setState(McpClientState.connected);
        // Recovery signal — spec 082 FR-004: fire AFTER the state
        // transition so listeners inspecting `state` see `connected`.
        _reconnectedController.add(null);
      }
    }
  }

  @override
  Stream<void> get onToolsChanged => _toolsChangedController.stream;

  @override
  Stream<void> get onReconnected => _reconnectedController.stream;

  @override
  McpClientState get state => _state;
}
