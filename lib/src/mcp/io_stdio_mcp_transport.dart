// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#15 (spec 015-mcp-client).
//
// IoStdioMcpTransport — concrete [McpWire] over dart:io Process.start
// + stdin/stdout JSON-RPC. THIS FILE IS ON THE RUNTIME-PURITY
// ALLOWLIST in .github/workflows/pipeline.yml (constitution VII).
//
// The bodies throw UnimplementedError so the file analyzes cleanly
// without forcing real subprocess I/O in tests. The StdioMcpClient
// unit tests use a fake McpWire (test/mcp/_fake_wire.dart), not this
// adapter — full subprocess behavior is verified in a future
// integration-test PR (tracked separately).

import 'dart:async';

import 'mcp_wire.dart';

/// Concrete [McpWire] over stdio (subprocess JSON-RPC). Stub — see
/// file header.
class IoStdioMcpTransport implements McpWire {
  final String executable;
  final List<String> args;

  bool _isOpen = false;
  final StreamController<McpWireNotification> _notifications =
      StreamController<McpWireNotification>.broadcast();

  IoStdioMcpTransport({
    required this.executable,
    this.args = const [],
  });

  @override
  Future<void> open() async {
    // TODO(spec-015-followup): implement Process.start + stdin/stdout
    // JSON-RPC. For now, throw so any production wiring fails loudly.
    throw UnimplementedError(
      'IoStdioMcpTransport.open not yet implemented — see spec 015 plan.md Phase 8',
    );
  }

  @override
  Future<void> close() async {
    _isOpen = false;
    await _notifications.close();
  }

  @override
  Future<McpWireResponse> send(McpWireRequest request) async {
    throw UnimplementedError(
      'IoStdioMcpTransport.send not yet implemented — see spec 015 plan.md Phase 8',
    );
  }

  @override
  Stream<McpWireNotification> get notifications => _notifications.stream;

  @override
  bool get isOpen => _isOpen;
}
