/// Stdio Transport — process-based MCP with restart policy.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'transport.dart';
import 'stdio_transport_config.dart';
import 'restart_policy.dart';

/// Stdio Transport — MCP over stdio with process management and restart policy.
class StdioTransport implements McpTransport {
  @override
  final String type = 'stdio';

  final StdioTransportConfig config;
  
  Process? _process;
  StreamController<void>? _toolsChangedController;
  bool _isConnected = false;
  int _restartAttempts = 0;
  Timer? _healthCheckTimer;
  final Map<int, Completer<McpToolResult>> _pendingCalls = {};
  int _nextId = 0;

  StdioTransport({required this.config});

  @override
  Future<void> connect() async {
    _toolsChangedController = StreamController<void>.broadcast();
    await _startProcess();
    _startHealthCheck();
  }

  Future<void> _startProcess() async {
    _process = await Process.start(
      config.command,
      config.args,
      environment: config.env,
      mode: ProcessStartMode.normal,
    );

    unawaited(_process!.exitCode.then((code) {
      if (_isConnected) {
        _handleCrash();
      }
    }));

    // Parse stdout for JSON-RPC responses and tool list changes
    _process!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_handleStdoutLine);

    _process!.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          print('MCP stderr: $line');
        });

    _isConnected = true;
    _restartAttempts = 0;
  }

  void _handleStdoutLine(String line) {
    if (line.isEmpty) return;
    
    try {
      final json = jsonDecode(line);
      
      // Check for tool list changed notification
      if (json['method'] == 'notifications/tools/list_changed') {
        _toolsChangedController?.add(null);
        return;
      }
      
      // Handle JSON-RPC responses
      if (json['id'] != null && json['result'] != null) {
        final id = json['id'] as int;
        final completer = _pendingCalls.remove(id);
        if (completer != null && !completer.isCompleted) {
          completer.complete(McpToolResult(
            content: jsonEncode(json['result']),
            isError: false,
          ));
        }
      } else if (json['id'] != null && json['error'] != null) {
        final id = json['id'] as int;
        final completer = _pendingCalls.remove(id);
        if (completer != null && !completer.isCompleted) {
          completer.complete(McpToolResult(
            content: '',
            isError: true,
            errorMessage: jsonEncode(json['error']),
          ));
        }
      }
    } catch (e) {
      // Ignore parse errors
    }
  }

  Future<void> _handleCrash() async {
    _isConnected = false;
    
    if (_restartAttempts < config.restartPolicy.maxRetries) {
      _restartAttempts++;
      final delay = config.restartPolicy.backoffDelaysMs[
          _restartAttempts.clamp(0, config.restartPolicy.backoffDelaysMs.length - 1)];
      
      await Future<void>.delayed(Duration(milliseconds: delay));
      await _startProcess();
    } else {
      // Max retries exceeded - complete all pending with error
      for (final completer in _pendingCalls.values) {
        if (!completer.isCompleted) {
          completer.complete(McpToolResult(
            content: '',
            isError: true,
            errorMessage: 'Stdio process crashed and max retries exceeded',
          ));
        }
      }
      _pendingCalls.clear();
    }
  }

  void _startHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isConnected) {
        timer.cancel();
        return;
      }
      // Send ping to check health
      _sendJsonRpc('ping', {}, _nextId++);
    });
  }

  Future<McpToolResult> _sendJsonRpc(String method, Map<String, dynamic> params, int id) async {
    final completer = Completer<McpToolResult>();
    _pendingCalls[id] = completer;
    
    final message = {
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': params,
    };
    
    _process?.stdin.writeln(jsonEncode(message));
    
    return completer.future.timeout(const Duration(seconds: 30), onTimeout: () {
      _pendingCalls.remove(id);
      if (!completer.isCompleted) {
        completer.complete(McpToolResult(
          content: '',
          isError: true,
          errorMessage: 'Request timeout',
        ));
      }
      return completer.future;
    });
  }

  @override
  Future<void> disconnect() async {
    _healthCheckTimer?.cancel();
    _process?.kill();
    await _process?.exitCode;
    await _toolsChangedController?.close();
    _isConnected = false;
  }

  @override
  Future<List<McpTool>> listTools() async {
    final result = await _sendJsonRpc('tools/list', {}, _nextId++);
    if (result.isError) return [];
    
    try {
      final json = jsonDecode(result.content);
      final tools = (json['tools'] as List).map((t) => McpTool(
        name: t['name'] as String,
        description: t['description'] as String? ?? '',
        inputSchema: t['inputSchema'] as Map<String, dynamic>,
      )).toList();
      return tools;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<McpToolResult> callTool(String name, Map<String, dynamic> arguments) async {
    return _sendJsonRpc('tools/call', <String, dynamic>{'name': name, 'arguments': arguments}, _nextId++);
  }

  @override
  Stream<void> get onToolsChanged => _toolsChangedController?.stream ?? const Stream.empty();
}