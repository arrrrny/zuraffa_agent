// Test helper — a fake [McpWire] used by the SSE/stdio MCP client
// tests. Records every interaction and can be programmed to drop /
// recover / emit notifications.

import 'dart:async';

import 'package:zuraffa_agent/src/mcp/mcp_wire.dart';

class FakeMcpWire implements McpWire {
  bool _isOpen = false;
  int openCallCount = 0;
  int closeCallCount = 0;
  final List<McpWireRequest> sentRequests = [];

  /// Queue of responses to return on subsequent [send] calls.
  /// If a response is a [Exception], it is thrown instead of returned.
  final List<Object> _responseQueue = [];

  final StreamController<McpWireNotification> _notifications =
      StreamController<McpWireNotification>.broadcast();

  /// Program the next [send] result. Either a [McpWireResponse] or
  /// an [Exception] (which [send] will throw).
  void enqueueNext(Object response) {
    _responseQueue.add(response);
  }

  void emitNotification(McpWireNotification n) {
    _notifications.add(n);
  }

  @override
  Future<void> open() async {
    openCallCount += 1;
    _isOpen = true;
  }

  @override
  Future<void> close() async {
    closeCallCount += 1;
    _isOpen = false;
    await _notifications.close();
  }

  @override
  Future<McpWireResponse> send(McpWireRequest request) async {
    sentRequests.add(request);
    if (_responseQueue.isEmpty) {
      throw StateError('FakeMcpWire: no enqueued response for $request');
    }
    final next = _responseQueue.removeAt(0);
    if (next is Exception) {
      throw next;
    }
    if (next is McpWireResponse) {
      return next;
    }
    throw StateError('FakeMcpWire: enqueued value must be Exception or McpWireResponse, got $next');
  }

  @override
  Stream<McpWireNotification> get notifications => _notifications.stream;

  @override
  bool get isOpen => _isOpen;
}
