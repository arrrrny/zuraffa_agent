// Test fixture — a mock MCP server speaking the newline-delimited JSON-RPC
// dialect of specs/105-production-mcp-transports/contracts/mcp-wire-dialect.md.
// Run as a subprocess by the IoStdioMcpTransport integration tests:
//   dart test/mcp/_mock_stdio_mcp_server.dart <mode>
// Modes: echo | garbage | notify | crash | slow (see
// io_stdio_mcp_transport_test.dart).
import 'dart:convert';
import 'dart:io';

/// Repo-relative path to this script — shared by the transport tests so the
/// spawn target is declared once, next to the script it names.
final mockScriptPath = 'test/mcp/_mock_stdio_mcp_server.dart';

void emit(Map<String, Object?> json) {
  stdout.writeln(jsonEncode(json));
  stdout.flush();
}

void answerToolsList(Object? id) {
  emit({
    'jsonrpc': '2.0',
    'id': id,
    'result': {
      'tools': [
        {
          'name': 'echo',
          'description': 'Echoes arguments',
          'paramsSchema': {'type': 'object'},
        },
      ],
    },
  });
}

void answerCall(Object? id, Map<String, dynamic> params) {
  final name = params['name'] as String?;
  final arguments = (params['arguments'] as Map?) ?? const {};
  if (name == 'boom') {
    emit({
      'jsonrpc': '2.0',
      'id': id,
      'error': {'code': -32601, 'message': 'tool exploded'},
    });
    return;
  }
  emit({
    'jsonrpc': '2.0',
    'id': id,
    'result': {'echo': arguments},
  });
}

void main(List<String> args) {
  final mode = args.isNotEmpty ? args[0] : 'echo';

  // Junk before anything else: a non-JSON log-noise line and a valid
  // JSON-RPC response for an id no one has asked about yet (999).
  if (mode == 'garbage') {
    stdout.writeln('NOT JSON AT ALL — just a chatty log line');
    stdout.writeln(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': 999,
        'result': {'tools': <String>[]},
      }),
    );
    stdout.flush();
  }

  // A server-pushed tools-changed notification before any request.
  if (mode == 'notify') {
    emit({'jsonrpc': '2.0', 'method': 'notifications/tools/list_changed'});
  }

  stdin.transform(utf8.decoder).transform(const LineSplitter()).listen((
    line,
  ) async {
    Map<String, dynamic> request;
    try {
      final decoded = jsonDecode(line);
      if (decoded is! Map<String, dynamic>) return;
      request = decoded;
    } on FormatException {
      return; // garbage tolerance is the transport's job, not ours
    }
    final id = request['id'];
    final method = request['method'];
    if (method == 'tools/list') {
      answerToolsList(id);
    } else if (method == 'tools/call') {
      final params =
          (request['params'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      if (mode == 'crash' && params['name'] == 'crash') {
        stderr.writeln('mock: crashing on command');
        exit(1);
      }
      if (mode == 'slow') {
        // Long enough for the test to close the transport mid-flight.
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
      answerCall(id, params);
    }
  });
}
