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
  bool _closed = false;
  int _nextId = 0;
  final Map<int, Completer<McpWireResponse>> _pending = {};
  final StreamController<McpWireNotification> _notifications =
      StreamController<McpWireNotification>.broadcast();

  IoStdioMcpTransport({
    required this.executable,
    this.args = const [],
  }) {
    if (executable.trim().isEmpty) {
      throw ArgumentError.value(
          executable, 'executable', 'must be a non-empty command');
    }
  }

  @override
  Future<void> open() async {
    final process = await Process.start(executable, args);
    _process = process;
    // Drain the pipes from day one: a child blocked on a full stdout
    // buffer is a hung session. Line semantics arrive with the send path.
    _stdoutSub = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_handleLine);
    _stderrSub = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((_) {});
    _isOpen = true;
    unawaited(process.exitCode.then((_) => _handleExit()));
  }

  /// A child exit (crash or normal) is a dropped session: the open signal
  /// goes off, in-flight sends fail typed — the reconnect policy's signal —
  /// and the notification stream is done.
  void _handleExit() {
    if (_closed) return;
    _isOpen = false;
    final failure = const McpWireClosedException(
        'IoStdioMcpTransport: the server process exited');
    for (final completer in _pending.values) {
      completer.completeError(failure);
    }
    _pending.clear();
    _notifications.close();
  }

  @override
  Future<void> close() async {
    _closed = true;
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
    final process = _process;
    if (!_isOpen || process == null) {
      throw const McpWireClosedException(
          'IoStdioMcpTransport: send on a transport that is not open');
    }
    final id = _nextId++;
    final completer = Completer<McpWireResponse>();
    _pending[id] = completer;
    final Map<String, Object?> envelope;
    switch (request) {
      case McpWireRequestListTools():
        envelope = {
          'jsonrpc': '2.0',
          'id': id,
          'method': 'tools/list',
          'params': <String, Object?>{},
        };
      case McpWireRequestCallTool(name: final name, arguments: final arguments):
        envelope = {
          'jsonrpc': '2.0',
          'id': id,
          'method': 'tools/call',
          'params': {'name': name, 'arguments': arguments},
        };
    }
    process.stdin.writeln(jsonEncode(envelope));
    await process.stdin.flush();
    return completer.future;
  }

  void _handleLine(String line) {
    Map<String, dynamic> message;
    try {
      final decoded = jsonDecode(line);
      if (decoded is! Map<String, dynamic>) return;
      message = decoded;
    } on FormatException {
      return; // log-noise lines are skipped (pinned at U7)
    }
    final id = message['id'];
    if (id is int && _pending.containsKey(id)) {
      _pending.remove(id)!.complete(_responseFor(message));
      return;
    }
    // Server-pushed notification (no id): only the tools-changed method has
    // semantic meaning on this seam.
    if (message['method'] == 'notifications/tools/list_changed') {
      _notifications.add(const McpWireNotificationToolsChanged());
    }
  }

  /// Maps a JSON-RPC response object onto the sealed response family:
  /// an `error` object becomes the typed error (application-level failure),
  /// anything else carries its `result` map.
  McpWireResponse _responseFor(Map<String, dynamic> message) {
    final error = message['error'];
    if (error is Map) {
      return McpWireResponseError(
        code: error['code']?.toString() ?? '',
        message: error['message']?.toString() ?? '',
      );
    }
    final result = (message['result'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    return McpWireResponseOk(result);
  }

  @override
  Stream<McpWireNotification> get notifications => _notifications.stream;

  @override
  bool get isOpen => _isOpen;
}
