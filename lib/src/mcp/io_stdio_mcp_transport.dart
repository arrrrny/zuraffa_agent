// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#15 (spec 015-mcp-client); implemented in
// spec 105 (issue arrrrny/zuraffa_agent#107).
//
// IoStdioMcpTransport — concrete [McpWire] over dart:io Process.start
// + stdin/stdout newline-delimited JSON-RPC 2.0, per the wire contract in
// specs/105-production-mcp-transports/contracts/mcp-wire-dialect.md.
// THIS FILE IS ON THE RUNTIME-PURITY ALLOWLIST in
// .github/workflows/pipeline.yml (constitution VII).
//
// Transport-level failures THROW (typed [McpWireClosedException]) so the
// clients' reconnect policy (spec 082) sees a drop; JSON-RPC *error
// responses* map to [McpWireResponseError] instead. The SSE/stdio unit
// tests use a fake McpWire (test/mcp/_fake_wire.dart); this adapter's real
// subprocess behavior is integration-tested against
// test/mcp/_mock_stdio_mcp_server.dart.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'mcp_wire.dart';

/// Typed transport failure: the wire is not open (used before open, after
/// close, or after the child process exited).
class McpWireClosedException implements Exception {
  final String message;
  const McpWireClosedException(this.message);
  @override
  String toString() => 'McpWireClosedException: $message';
}

/// Concrete [McpWire] over stdio (subprocess JSON-RPC). See file header.
class IoStdioMcpTransport implements McpWire {
  final String executable;
  final List<String> args;

  Process? _process;
  StreamSubscription<String>? _stdoutSub;
  StreamSubscription<String>? _stderrSub;
  bool _isOpen = false;
  final StreamController<McpWireNotification> _notifications =
      StreamController<McpWireNotification>.broadcast();

  IoStdioMcpTransport({
    required this.executable,
    this.args = const [],
  });

  @override
  Future<void> open() async {
    final process = await Process.start(executable, args);
    _process = process;
    // Drain the pipes from day one: a child blocked on a full stdout
    // buffer is a hung session. Line semantics arrive with the send path.
    _stdoutSub = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((_) {});
    _stderrSub = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((_) {});
    _isOpen = true;
  }

  @override
  Future<void> close() async {
    _isOpen = false;
    _process?.kill();
    _process = null;
    await _stdoutSub?.cancel();
    _stdoutSub = null;
    await _stderrSub?.cancel();
    _stderrSub = null;
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
