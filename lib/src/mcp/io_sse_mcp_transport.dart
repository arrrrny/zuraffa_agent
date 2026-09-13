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
  int _nextId = 0;
  final StreamController<McpWireNotification> _notifications =
      StreamController<McpWireNotification>.broadcast();

  IoSseMcpTransport({required this.endpoint, this.bearerToken}) {
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
      throw ArgumentError.value(endpoint, 'endpoint', 'must be an http(s) URL');
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
    } on SocketException catch (e) {
      client.close(force: true);
      throw McpWireOpenException(
        'IoSseMcpTransport: connection failed: ${e.message}',
      );
    }
    request.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
    _applyAuth(request);
    final HttpClientResponse response;
    try {
      response = await request.close();
    } on SocketException catch (e) {
      client.close(force: true);
      throw McpWireOpenException(
        'IoSseMcpTransport: connection dropped during open: ${e.message}',
      );
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
    // The event stream is parsed incrementally (WHATWG subset, see the
    // dialect contract): comment/keep-alives and non-data fields ignored,
    // `data:` fields joined per event, events separated by blank lines.
    response
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_handleStreamLine, onError: (Object _) {}, cancelOnError: true);
  }

  final List<String> _dataBuffer = <String>[];

  void _handleStreamLine(String line) {
    if (line.isEmpty) {
      if (_dataBuffer.isEmpty) return;
      final payload = _dataBuffer.join('\n');
      _dataBuffer.clear();
      _dispatchStreamPayload(payload);
      return;
    }
    if (line.startsWith(':')) return; // comment / keep-alive
    final colon = line.indexOf(':');
    final field = colon == -1 ? line : line.substring(0, colon);
    var value = colon == -1 ? '' : line.substring(colon + 1);
    if (value.startsWith(' ')) value = value.substring(1);
    if (field == 'data') _dataBuffer.add(value);
    // `event:`, `id:`, `retry:` fields are accepted and ignored.
  }

  void _dispatchStreamPayload(String payload) {
    if (payload.isEmpty) return;
    Map<String, dynamic> message;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return;
      message = decoded;
    } on FormatException {
      return;
    }
    if (message['method'] == 'notifications/tools/list_changed') {
      _notifications.add(const McpWireNotificationToolsChanged());
    }
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
    final client = _client;
    if (!_isOpen || client == null) {
      throw const McpWireClosedException(
        'IoSseMcpTransport: send on a transport that is not open',
      );
    }
    final id = _nextId++;
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
    final HttpClientRequest post;
    try {
      post = await client.postUrl(_uri);
    } on SocketException {
      throw const McpWireClosedException(
        'IoSseMcpTransport: the connection was refused during send',
      );
    }
    post.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    _applyAuth(post);
    post.write(jsonEncode(envelope));
    final HttpClientResponse response;
    try {
      response = await post.close();
    } on SocketException {
      throw const McpWireClosedException(
        'IoSseMcpTransport: the connection dropped during send',
      );
    }
    final body = await utf8.decoder.bind(response).join();
    if (response.statusCode < 200 || response.statusCode > 299) {
      throw McpWireClosedException(
        'IoSseMcpTransport: the endpoint answered HTTP '
        '${response.statusCode} for ${envelope['method']}',
      );
    }
    final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(body) as Map<String, dynamic>;
    } on FormatException {
      throw McpWireClosedException(
        'IoSseMcpTransport: undecodable response body for '
        '${envelope['method']}',
      );
    }
    final error = decoded['error'];
    if (error is Map) {
      return McpWireResponseError(
        code: error['code']?.toString() ?? '',
        message: error['message']?.toString() ?? '',
      );
    }
    final result =
        (decoded['result'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    return McpWireResponseOk(result);
  }

  @override
  Stream<McpWireNotification> get notifications => _notifications.stream;

  @override
  bool get isOpen => _isOpen;
}
