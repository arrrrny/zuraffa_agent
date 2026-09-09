// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#15 (spec 015-mcp-client); implemented in
// spec 105 (issue arrrrny/zuraffa_agent#107).
//
// IoSseMcpTransport — concrete [McpWire] over dart:io HttpClient: a
// `text/event-stream` GET for server pushes, a JSON-RPC 2.0 POST per RPC,
// per the wire contract in
// specs/105-production-mcp-transports/contracts/mcp-wire-dialect.md.
// THIS FILE IS ON THE RUNTIME-PURITY ALLOWLIST in
// .github/workflows/pipeline.yml (constitution VII).
//
// Transport-level failures THROW (typed [McpWireOpenException] /
// [McpWireClosedException]) so the clients' reconnect policy (spec 082)
// sees a drop; JSON-RPC *error responses* map to [McpWireResponseError]
// instead. The SseMcpClient unit tests use a fake McpWire
// (test/mcp/_fake_wire.dart); this adapter's real network behavior is
// integration-tested against a loopback HttpServer mock.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'io_stdio_mcp_transport.dart' show McpWireClosedException;
import 'mcp_wire.dart';

/// Typed failure for a failed stream open: names the HTTP status, or null
/// when the connection itself failed.
class McpWireOpenException implements Exception {
  final int? statusCode;
  final String message;
  const McpWireOpenException(this.message, {this.statusCode});
  @override
  String toString() => 'McpWireOpenException: $message';
}

/// Concrete [McpWire] over SSE + Bearer. See file header.
class IoSseMcpTransport implements McpWire {
  final String endpoint;
  final String? bearerToken;

  HttpClient? _client;
  bool _isOpen = false;
  final StreamController<McpWireNotification> _notifications =
      StreamController<McpWireNotification>.broadcast();

  IoSseMcpTransport({
    required this.endpoint,
    this.bearerToken,
  }) {
    final uri = Uri.tryParse(endpoint);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw ArgumentError.value(endpoint, 'endpoint', 'must be an http(s) URL');
    }
  }

  Uri get _uri {
    final uri = Uri.tryParse(endpoint);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        !uri.hasScheme) {
      throw ArgumentError.value(
          endpoint, 'endpoint', 'must be an http(s) URL');
    }
    return uri;
  }

  void _applyAuth(HttpClientRequest request) {
    final token = bearerToken;
    if (token != null) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
  }

  @override
  Future<void> open() async {
    if (_isOpen) return; // idempotent: never open a second stream
    final client = HttpClient();
    final HttpClientRequest request;
    try {
      request = await client.getUrl(_uri);
    } on Object {
      client.close(force: true);
      rethrow;
    }
    request.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
    _applyAuth(request);
    final HttpClientResponse response;
    try {
      response = await request.close();
    } on Object {
      client.close(force: true);
      rethrow;
    }
    if (response.statusCode != HttpStatus.ok) {
      final status = response.statusCode;
      response.drain<void>().ignore();
      client.close(force: true);
      throw McpWireOpenException(
        'IoSseMcpTransport: the endpoint answered HTTP $status',
        statusCode: status,
      );
    }
    _client = client;
    _isOpen = true;
    // Stream content is consumed from U18 onward (notifications parsing);
    // drain errors so an aborted stream never becomes an unhandled error.
    response.listen((_) {}, onError: (Object _) {}, cancelOnError: false);
  }

  @override
  Future<void> close() async {
    _isOpen = false;
    _client?.close(force: true);
    _client = null;
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
