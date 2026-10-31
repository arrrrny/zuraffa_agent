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
import 'mcp_wire_validation.dart';

/// Typed transport failure: the wire is not open (used before open, after
/// close, or after the child process exited).
class McpWireClosedException implements Exception {
  /// The message.
  final String message;

  /// Creates an MCP wire closed exception.
  const McpWireClosedException(this.message);
  @override
  String toString() => 'McpWireClosedException: $message';
}

/// Marker line emitted by [_budgetedLineFramer] when a child's stdout line
/// exceeds the byte budget. The oversized reply is unroutable — its JSON-RPC
/// id is only knowable by buffering the whole line, the very thing the
/// budget refuses — so [IoStdioMcpTransport] fails every outstanding request
/// typed with `response-too-large` when it sees this marker (the session
/// itself survives, per the wire-boundary rejection policy).
const String _oversizedLineMarker = '__MCP_WIRE_LINE_OVER_BUDGET__';

/// Byte-budgeted replacement for `const LineSplitter()` on the child's
/// stdout (issue #131 follow-up). `LineSplitter` buffers an entire line
/// before any consumer sees it, so a buggy or hostile child emitting one
/// unbounded line would be fully buffered before the wire validator's size
/// cap could reject it. This framer counts bytes per line and trips at
/// [maxResponseBytes]: the rest of the offending line is discarded (read to
/// the next newline without buffering), the marker line is emitted instead,
/// and framing resyncs at the next newline — bounding the memory spent on
/// any single line to the cap. The stream never errors on a trip, so the
/// session survives. Under-budget lines (including empty ones, and `\n`,
/// `\r\n` and `\r` terminators) are framed exactly like `LineSplitter`.
StreamTransformer<List<int>, String> _budgetedLineFramer({
  required int maxResponseBytes,
}) {
  var line = <int>[];
  var overBudget = false;
  var pendingCr = false;
  void endLine(EventSink<String> sink) {
    sink.add(overBudget ? _oversizedLineMarker : utf8.decode(line));
    line = <int>[];
    overBudget = false;
  }

  return StreamTransformer<List<int>, String>.fromHandlers(
    handleData: (List<int> chunk, EventSink<String> sink) {
      for (final byte in chunk) {
        if (pendingCr) {
          pendingCr = false;
          if (byte == 0x0A) continue; // second half of \r\n
        }
        if (byte == 0x0D) {
          endLine(sink);
          pendingCr = true;
          continue;
        }
        if (byte == 0x0A) {
          endLine(sink);
          continue;
        }
        if (overBudget) continue; // discard the rest of the offending line
        if (line.length >= maxResponseBytes) {
          overBudget = true;
          continue;
        }
        line.add(byte);
      }
    },
    handleDone: (EventSink<String> sink) {
      // Dialect §2: a trailing partial line at EOF is discarded (an
      // over-budget partial line never reaches the wire validator either).
      sink.close();
    },
  );
}

/// Concrete [McpWire] over stdio (subprocess JSON-RPC). See file header.
class IoStdioMcpTransport implements McpWire {
  /// The executable.
  final String executable;

  /// The args.
  final List<String> args;

  /// Wire-boundary validation (issue #131). Every line the child answers a
  /// pending request with is validated against the JSON-RPC 2.0 envelope,
  /// the size cap and the content policy before the pending send completes;
  /// violations come back as typed `McpWireResponseError`s, never as
  /// unvalidated payloads.
  final McpWireValidator _validator;

  Process? _process;
  StreamSubscription<String>? _stdoutSub;
  StreamSubscription<String>? _stderrSub;
  bool _isOpen = false;
  bool _closed = false;
  int _nextId = 0;
  final Map<int, Completer<McpWireResponse>> _pending = {};
  final StreamController<McpWireNotification> _notifications =
      StreamController<McpWireNotification>.broadcast();

  /// Creates a I/O stdio MCP transport.
  IoStdioMcpTransport({
    required this.executable,
    this.args = const [],
    int? maxResponseBytes,
  }) : _validator = McpWireValidator(
         maxResponseBytes: maxResponseBytes ?? defaultMcpWireMaxResponseBytes,
       ) {
    if (executable.trim().isEmpty) {
      throw ArgumentError.value(
        executable,
        'executable',
        'must be a non-empty command',
      );
    }
  }

  @override
  Future<void> open() async {
    if (_isOpen) return; // idempotent: never spawn a second session
    final process = await Process.start(executable, args);
    _process = process;
    // Drain the pipes from day one: a child blocked on a full stdout
    // buffer is a hung session. Line semantics arrive with the send path.
    // The stdout line framer is byte-budgeted (issue #131 follow-up): an
    // unbounded child line is failed at the budget instead of being fully
    // buffered first — see [_budgetedLineFramer].
    _stdoutSub = process.stdout
        .transform(
          _budgetedLineFramer(maxResponseBytes: _validator.maxResponseBytes),
        )
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
    _failPending('the server process exited');
    _notifications.close();
  }

  void _failPending(String reason) {
    final failure = McpWireClosedException('IoStdioMcpTransport: $reason');
    for (final completer in _pending.values) {
      completer.completeError(failure);
    }
    _pending.clear();
  }

  /// Completes every outstanding request with the typed
  /// `response-too-large` rejection (see [_oversizedLineMarker]): the
  /// oversized reply line was unroutable, so its id is unknowable, and an
  /// outstanding request must never hang on a reply that can never arrive
  /// in routable form.
  void _failPendingTooLarge() {
    final rejection = McpWireResponseError(
      code: 'response-too-large',
      message:
          'IoStdioMcpTransport: a response line exceeded the '
          '${_validator.maxResponseBytes}-byte wire cap and cannot be '
          'routed to its request',
    );
    for (final completer in _pending.values) {
      completer.complete(rejection);
    }
    _pending.clear();
  }

  @override
  Future<void> close() async {
    _closed = true;
    _isOpen = false;
    final process = _process;
    _process = null;
    process?.kill();
    if (process != null) {
      // An uncooperative child that ignores SIGTERM must not linger holding
      // its pipes after the transport reports closed — escalate, bounded so
      // close() never hangs.
      try {
        await process.exitCode.timeout(const Duration(milliseconds: 250));
      } on TimeoutException {
        process.kill(ProcessSignal.sigkill);
      }
    }
    _failPending('the transport was closed');
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
        'IoStdioMcpTransport: send on a transport that is not open',
      );
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
    try {
      process.stdin.writeln(jsonEncode(envelope));
      // The completer future is returned (and thus subscribed) synchronously:
      // a close/exit completing this pending entry in the same turn can never
      // produce an unhandled rejection. Flush errors mean the pipe died —
      // exactly the path where close/exit drains the pending entry typed.
      unawaited(process.stdin.flush().catchError((Object _) {}));
    } on Object {
      // The child died between the guard and the write: keep the typed
      // failure contract (never an untyped platform exception).
      throw const McpWireClosedException(
        'IoStdioMcpTransport: the server process is gone',
      );
    }
    return completer.future;
  }

  void _handleLine(String line) {
    if (line == _oversizedLineMarker) {
      // The byte-budgeted framer tripped: a child line exceeded
      // maxResponseBytes. Its JSON-RPC id is unknowable without buffering
      // the whole line — exactly what the budget exists to refuse — so the
      // oversized reply is unroutable. Every outstanding request is failed
      // typed rather than hung; the session itself survives (a wire
      // rejection is not a transport drop).
      _failPendingTooLarge();
      return;
    }
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
      // Issue #131: the response is validated at the wire boundary (JSON-RPC
      // envelope, size cap, content policy) before the pending send resolves;
      // a violation completes the request as a typed error response.
      // `expectedId` is the line's own id, so the validator's id-match check
      // is vacuous on this seam by construction: id matching is enforced by
      // the `_pending` map key above (a reply with a foreign id never reaches
      // this branch). The check becomes the real enforcement point if stdio
      // ever moves to server-assigned ids.
      _pending
          .remove(id)!
          .complete(
            _validator.validateResponse(
              rawBody: line,
              message: message,
              expectedId: id,
            ),
          );
      return;
    }
    // Server-pushed notification (no id): only the tools-changed method has
    // semantic meaning on this seam.
    if (message['method'] == 'notifications/tools/list_changed') {
      _notifications.add(const McpWireNotificationToolsChanged());
    }
  }

  @override
  Stream<McpWireNotification> get notifications => _notifications.stream;

  @override
  bool get isOpen => _isOpen;
}
