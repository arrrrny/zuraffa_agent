// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#15 (spec 015-mcp-client).
//
// SseMcpClient — the SSE+Bearer MCP transport. Delegates to an
// [McpWire] seam so the client itself is pure (no dart:io); the real
// SSE adapter lives in lib/src/mcp/io_sse_mcp_transport.dart (purity
// allowlisted). On transport drop, runs [McpReconnectPolicy] with the
// SSE config — reconnects within 5s (Spec 015 SC-002).
//
// Token rotation: the auth callback is invoked before each connect /
// reconnect; if it returns a new token, the wire is rebuilt with the
// fresh token. This satisfies Spec 015 FR-003 ("auth callback for
// token rotation").

import 'dart:async';

import '../domain/entities/mcp_transport/mcp_transport.dart';
import 'mcp_call_result.dart';
import 'mcp_client.dart';
import 'mcp_reconnect_policy.dart';
import 'mcp_tool_descriptor.dart';
import 'mcp_wire.dart';

/// Function that returns a fresh bearer token. Called before each
/// connect / reconnect so expiring tokens can be rotated without
/// rebuilding the client.
typedef McpAuthTokenCallback = Future<String?> Function();

/// Factory that builds a fresh [McpWire] for a given bearer token.
/// The SSE client uses this to rebuild the wire when the auth callback
/// rotates the token.
typedef McpWireFactory = McpWire Function(String? bearerToken);

/// SSE+Bearer MCP client.
///
/// Construction:
///   ```dart
///   final client = SseMcpClient(
///     transport: myTransport,
///     wireFactory: (token) => IoSseMcpTransport(endpoint: ..., bearerToken: token),
///     authTokenCallback: () async => await myVault.fetch('mcp-bearer'),
///   );
///   await client.connect();
///   ```
class SseMcpClient implements McpClient {
  @override
  final McpTransport transport;

  final McpWireFactory _wireFactory;
  final McpAuthTokenCallback? _authTokenCallback;
  final McpReconnectPolicy _reconnect;

  McpWire? _wire;
  String? _currentToken;
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

  SseMcpClient({
    required this.transport,
    required McpWireFactory wireFactory,
    McpAuthTokenCallback? authTokenCallback,
    McpReconnectPolicy? reconnectPolicy,
    required McpClock now,
    required McpDelay delay,
  })  : _wireFactory = wireFactory,
        _authTokenCallback = authTokenCallback,
        _reconnect = reconnectPolicy ??
            McpReconnectPolicy(
              config: McpReconnectPolicyConfig.sse,
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
      _currentToken = await _authTokenCallback?.call();
      _wire = _wireFactory(_currentToken);
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
      throw StateError('SseMcpClient.listTools called in state $_state');
    }
    final resp = await _callWithReconnect(
      const McpWireRequestListTools(),
    );
    if (resp is! McpWireResponseOk) {
      final err = resp as McpWireResponseError;
      throw StateError('SseMcpClient.listTools: ${err.code}: ${err.message}');
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
        message: 'SseMcpClient.callTool in state $_state',
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
        message: 'SseMcpClient.callTool($name) threw: $e',
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
        // Rotate token if callback is configured.
        if (_authTokenCallback != null) {
          _currentToken = await _authTokenCallback.call();
          _wire = _wireFactory(_currentToken);
        }
        await _reconnect.nextBackoff();
        await _wire!.open();
        _setState(McpClientState.connected);
        // Recovery signal — spec 082 FR-004: fire AFTER the state
        // transition so listeners inspecting `state` see `connected`.
        // Lets [ToolListingCache] drop listings that predate the
        // disconnect (the severed transport may have missed a
        // tools-changed notification).
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
