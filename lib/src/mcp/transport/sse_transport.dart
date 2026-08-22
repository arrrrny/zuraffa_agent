/// SSE Transport — HTTP+Bearer with reconnect and auth callback.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth_callback.dart';
import 'transport.dart';
import 'sse_transport_config.dart';

/// SSE Transport — MCP over Server-Sent Events with Bearer auth.
class SseTransport implements McpTransport {
  @override
  final String type = 'sse';

  final SseTransportConfig config;
  final AuthCallback? authCallback;
  
  http.Client? _client;
  StreamSubscription<void>? _sseSubscription;
  StreamController<void>? _toolsChangedController;
  int _reconnectAttempts = 0;

  SseTransport({
    required this.config,
    this.authCallback,
  });

  @override
  Future<void> connect() async {
    _client = http.Client();
    _toolsChangedController = StreamController<void>.broadcast();
    await _connectWithRetry();
  }

  Future<void> _connectWithRetry() async {
    while (_reconnectAttempts < config.reconnectPolicy.maxRetries) {
      try {
        await _establishConnection();
        _reconnectAttempts = 0;
        return;
      } catch (e) {
        _reconnectAttempts++;
        if (_reconnectAttempts >= config.reconnectPolicy.maxRetries) {
          rethrow;
        }
        final delay = _calculateBackoff();
        await Future<void>.delayed(delay);
      }
    }
  }

  Future<void> _establishConnection() async {
    final uri = Uri.parse(config.endpoint);
    final request = http.Request('GET', uri)
      ..headers['Accept'] = 'text/event-stream'
      ..headers['Authorization'] = 'Bearer ${config.bearerToken}';

    final streamedResponse = await _client!.send(request);
    
    if (streamedResponse.statusCode == 401 && authCallback != null) {
      final newToken = await authCallback!();
      // Retry with new token
      request.headers['Authorization'] = 'Bearer $newToken';
      final retryResponse = await _client!.send(request);
      if (retryResponse.statusCode != 200) {
        throw Exception('SSE connection failed: ${retryResponse.statusCode}');
      }
    } else if (streamedResponse.statusCode != 200) {
      throw Exception('SSE connection failed: ${streamedResponse.statusCode}');
    }

    // Parse SSE events
    await for (final event in _parseSseStream(streamedResponse.stream)) {
      if (event.isEmpty) continue;
      // Handle tool list updates from server
      if (event == 'tools_changed') {
        _toolsChangedController?.add(null);
      }
    }
  }

  Stream<String> _parseSseStream(Stream<List<int>> byteStream) async* {
    final decoder = utf8.decoder;
    final lines = decoder.bind(byteStream).transform(const LineSplitter());
    
    String? currentEvent;
    final dataBuffer = StringBuffer();
    
    await for (final line in lines) {
      if (line.isEmpty) {
        if (currentEvent != null && dataBuffer.isNotEmpty) {
          yield dataBuffer.toString();
          dataBuffer.clear();
          currentEvent = null;
        }
        continue;
      }
      
      if (line.startsWith('event:')) {
        currentEvent = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        dataBuffer.write(line.substring(5).trim());
        dataBuffer.write('\n');
      }
    }
  }

  Duration _calculateBackoff() {
    final policy = config.reconnectPolicy;
    final base = policy.baseDelayMs;
    final max = policy.maxDelayMs;
    final multiplier = policy.multiplier;
    final jitter = policy.jitterFactor;
    
    double delay = base * (multiplier * _reconnectAttempts);
    delay = delay.clamp(base.toDouble(), max.toDouble());
    delay += delay * jitter * (2 * (DateTime.now().millisecond / 1000) - 1);
    
    return Duration(milliseconds: delay.floor());
  }

  @override
  Future<void> disconnect() async {
    await _sseSubscription?.cancel();
    await _toolsChangedController?.close();
    _client?.close();
  }

  @override
  Future<List<McpTool>> listTools() async {
    // Call MCP tools/list method via JSON-RPC over SSE
    // This is a simplified implementation
    return [];
  }

  @override
  Future<McpToolResult> callTool(String name, Map<String, dynamic> arguments) async {
    // Call MCP tools/call method via JSON-RPC over SSE
    // This is a simplified implementation
    return McpToolResult(content: '', isError: true, errorMessage: 'Not implemented');
  }

  @override
  Stream<void> get onToolsChanged => _toolsChangedController?.stream ?? const Stream.empty();
}