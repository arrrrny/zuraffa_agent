// Observability seam (issue #133, O-1/O-2) — tracing + metrics decorators.
//
// [ToolDispatcher] and [McpClient] are abstract interfaces; these
// decorators wrap any implementation and add the per-call spans and the
// tool-call failure counter without touching the wrapped object.
//
// [MissionRunner] wraps its dispatcher automatically when a tracer or
// metrics is injected — pass a pre-wrapped [TracedToolDispatcher] to the
// runner only when constructing it WITHOUT observability and want the
// spans anyway. The MCP decorator is consumer-side: wrap your client
// before handing it to the tool adapter (see [TracedMcpClient]).

import '../engine/tool_dispatcher.dart';
import '../domain/entities/mcp_transport/mcp_transport.dart';
import '../domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
import '../mcp/mcp_call_guard.dart';
import '../mcp/mcp_call_result.dart';
import '../mcp/mcp_client.dart';
import '../mcp/mcp_tool_descriptor.dart';
import 'metrics.dart';
import 'tracing.dart';

/// Wraps a [ToolDispatcher]: one `tool.dispatch` span per dispatch (child
/// of the ambient span — the mission span under [MissionRunner.run]), one
/// `tool.dispatchBatch` span per batch, and `agent_tool_calls_failed_total`
/// incremented for every unsuccessful result — including dispatches that
/// threw and failed results inside a batch.
class TracedToolDispatcher implements ToolDispatcher {
  TracedToolDispatcher(this._inner, this._tracer, {Metrics? metrics})
    : _metrics = metrics ?? NoopMetrics.instance;

  final ToolDispatcher _inner;
  final Tracer _tracer;
  final Metrics _metrics;

  @override
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  }) async {
    final span = _tracer.startSpan(
      'tool.dispatch',
      attributes: {'tool.name': toolName},
    );
    try {
      final result = await _inner.dispatch(
        toolName: toolName,
        arguments: arguments,
        isInternalMission: isInternalMission,
      );
      span.setAttribute('tool.ok', result.success);
      if (!result.success) {
        _metrics.counter('agent_tool_calls_failed_total').inc();
      }
      return result;
    } catch (error, stackTrace) {
      span.recordError(error, stackTrace);
      // Review F5 (issue #133): a thrown dispatch is a failed tool call by
      // the series' own name — count it before the rethrow.
      _metrics.counter('agent_tool_calls_failed_total').inc();
      rethrow;
    } finally {
      span.end();
    }
  }

  @override
  Future<List<ToolDispatchResult>> dispatchBatch({
    required List<ToolCall> calls,
    required bool isInternalMission,
  }) async {
    final span = _tracer.startSpan(
      'tool.dispatchBatch',
      attributes: {'tool.batch_size': calls.length},
    );
    try {
      final results = await _inner.dispatchBatch(
        calls: calls,
        isInternalMission: isInternalMission,
      );
      // Review F5 (issue #133): batched failures count too — the series
      // is `agent_tool_calls_failed_total`, not `dispatch_threw_total`.
      final failed = results.where((r) => !r.success).length;
      if (failed > 0) {
        _metrics.counter('agent_tool_calls_failed_total').inc(failed);
      }
      return results;
    } catch (error, stackTrace) {
      span.recordError(error, stackTrace);
      rethrow;
    } finally {
      span.end();
    }
  }

  @override
  List<String> validateSchema({
    required Map<String, dynamic> schema,
    required Map<String, dynamic> arguments,
  }) => _inner.validateSchema(schema: schema, arguments: arguments);

  @override
  bool checkRiskTier({
    required String riskTier,
    required bool isInternalMission,
  }) => _inner.checkRiskTier(
    riskTier: riskTier,
    isInternalMission: isInternalMission,
  );
}

/// Wraps an [McpClient]: one `mcp.callTool` span per tool invocation, with
/// the error code attached on [McpCallError] outcomes. Wrap the client
/// before handing it to [McpToolAdapter] / the tool registry.
class TracedMcpClient implements McpClient {
  TracedMcpClient(this._inner, this._tracer);

  final McpClient _inner;
  final Tracer _tracer;

  @override
  McpTransport get transport => _inner.transport;

  @override
  Future<void> connect() => _inner.connect();

  @override
  Future<void> disconnect() => _inner.disconnect();

  @override
  Future<List<McpToolDescriptor>> listTools() => _inner.listTools();

  @override
  Future<McpCallResult> callTool(
    String name,
    Map<String, dynamic> arguments, {
    McpCallOptions? options,
  }) async {
    final span = _tracer.startSpan(
      'mcp.callTool',
      attributes: {'tool.name': name},
    );
    try {
      final result = await _inner.callTool(name, arguments, options: options);
      if (result is McpCallError) {
        span.setAttribute('mcp.error.code', result.code);
      }
      return result;
    } catch (error, stackTrace) {
      span.recordError(error, stackTrace);
      rethrow;
    } finally {
      span.end();
    }
  }

  @override
  Stream<void> get onToolsChanged => _inner.onToolsChanged;

  @override
  Stream<void> get onReconnected => _inner.onReconnected;

  @override
  McpClientState get state => _inner.state;
}
