/// Tool Dispatcher — interface for dispatching tool calls with risk tier enforcement.
library;

import 'approval_callback.dart';
import '../domain/entities/approval_request/approval_request.dart';
import '../domain/entities/tool_dispatch_result/tool_dispatch_result.dart';

/// Tool dispatcher interface.
abstract class ToolDispatcher {
  /// Dispatch a single tool call.
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  });

  /// Dispatch a batch of tool calls with execution mode support.
  Future<List<ToolDispatchResult>> dispatchBatch({
    required List<ToolCall> calls,
    required bool isInternalMission,
  });

  /// Validate arguments against a tool's JSON schema.
  List<String> validateSchema({
    required Map<String, dynamic> schema,
    required Map<String, dynamic> arguments,
  });

  /// Check if a tool's risk tier allows execution in the given mission context.
  bool checkRiskTier({
    required String riskTier,
    required bool isInternalMission,
  });
}

/// Represents a single tool call in a batch.
class ToolCall {
  const ToolCall({
    required this.toolName,
    required this.arguments,
    required this.executionMode,
  });

  final String toolName;
  final Map<String, dynamic> arguments;
  final String executionMode; // 'sequential' or 'parallel'
}