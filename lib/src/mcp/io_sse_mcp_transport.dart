// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#15 (spec 015-mcp-client).
//
// IoSseMcpTransport — concrete [McpWire] over dart:io HttpClient +
// Server-Sent-Events parser. THIS FILE IS ON THE RUNTIME-PURITY
// ALLOWLIST in .github/workflows/pipeline.yml (constitution VII).
//
// The bodies throw UnimplementedError so the file analyzes cleanly
// without forcing real network I/O in tests. The SseMcpClient unit
// tests use a fake McpWire (test/mcp/_fake_wire.dart), not this
// adapter — full networked behavior is verified in a future
// integration-test PR (tracked separately).

import 'dart:async';

import 'mcp_wire.dart';

/// Concrete [McpWire] over SSE + Bearer. Stub — see file header.
class IoSseMcpTransport implements McpWire {
  final String endpoint;
  final String? bearerToken;

  bool _isOpen = false;
  final StreamController<McpWireNotification> _notifications =
      StreamController<McpWireNotification>.broadcast();

  IoSseMcpTransport({
    required this.endpoint,
    this.bearerToken,
  });

  @override
  Future<void> open() async {
    // TODO(spec-015-followup): implement SSE over dart:io HttpClient.
    // For now, throw so any production wiring fails loudly rather than
    // silently faking success.
    throw UnimplementedError(
      'IoSseMcpTransport.open not yet implemented — see spec 015 plan.md Phase 8',
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
      'IoSseMcpTransport.send not yet implemented — see spec 015 plan.md Phase 8',
    );
  }

  @override
  Stream<McpWireNotification> get notifications => _notifications.stream;

  @override
  bool get isOpen => _isOpen;
}
