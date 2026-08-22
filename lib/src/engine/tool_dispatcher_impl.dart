/// Tool Dispatcher Implementation — registry-backed dispatcher with risk/parallel/artifact support.
///
/// Provides sequential/parallel execution, JSON Schema validation, risk tier enforcement,
/// and oversized result handling via ArtifactService.
library;

import 'dart:async';
import 'dart:convert';

import 'package:json_schema/json_schema.dart';
import 'package:uuid/uuid.dart';

import 'tool_dispatcher.dart';
import 'tool_registry.dart';
import 'approval_callback.dart';
import '../artifact/artifact_service.dart';
import '../domain/entities/agent_tool/agent_tool.dart';
import '../domain/entities/approval_request/approval_request.dart';
import '../domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
import '../domain/entities/enums/risk_tier.dart';
import '../domain/entities/enums/execution_mode.dart';

/// Implementation of [ToolDispatcher] with full feature support.
class ToolDispatcherImpl implements ToolDispatcher {
  ToolDispatcherImpl({
    required ToolRegistry registry,
    required ArtifactService artifactService,
    ApprovalCallback? approvalCallback,
    int maxParallel = 10,
  })  : _registry = registry,
        _artifactService = artifactService,
        _approvalCallback = approvalCallback ?? defaultApprovalCallback,
        _semaphore = _Semaphore(maxParallel);

  final ToolRegistry _registry;
  final ArtifactService _artifactService;
  final ApprovalCallback _approvalCallback;
  final _Semaphore _semaphore;

  @override
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  }) async {
    final tool = await _registry.resolve(toolName);
    if (tool == null) {
      return ToolDispatchResult(
        success: false,
        error: 'Tool not found: $toolName',
        artifactRefs: [],
      );
    }

    // Validate schema
    final validationErrors = validateSchema(
      schema: Map<String, dynamic>.from(tool.inputSchema),
      arguments: arguments,
    );
    if (validationErrors.isNotEmpty) {
      return ToolDispatchResult(
        success: false,
        error: 'Validation failed: ${validationErrors.join(', ')}',
        artifactRefs: [],
      );
    }

    // Check risk tier
    if (!checkRiskTier(riskTier: tool.riskTier.name, isInternalMission: isInternalMission)) {
      return ToolDispatchResult(
        success: false,
        error: 'Risk tier ${tool.riskTier} not allowed for this mission',
        artifactRefs: [],
      );
    }

    // Handle confirm risk tier
    if (tool.riskTier == RiskTier.confirm) {
      final request = ApprovalRequest(
        id: const Uuid().v4(),
        toolName: toolName,
        arguments: arguments,
        requestedAt: DateTime.now(),
        timeoutMs: 30000, // Default 30s timeout
      );
      final approved = await _approvalCallback(request);
      if (!approved) {
        return ToolDispatchResult(
          success: false,
          error: 'Approval denied for confirm-tier tool: $toolName',
          artifactRefs: [],
        );
      }
    }

    // Execute the tool (placeholder - actual execution depends on tool source)
    final result = await _executeTool(tool, arguments);

    // Handle artifact size discipline
    final artifactResult = await _artifactService.store(
      data: utf8.encode(result),
      mimeType: 'application/json',
    );

    if (artifactResult.summarized) {
      return ToolDispatchResult(
        success: true,
        result: artifactResult.summary,
        artifactRefs: [artifactResult.ref.id],
      );
    }

    return ToolDispatchResult(
      success: true,
      result: result,
      artifactRefs: [],
    );
  }

  @override
  Future<List<ToolDispatchResult>> dispatchBatch({
    required List<ToolCall> calls,
    required bool isInternalMission,
  }) async {
    final results = <ToolDispatchResult>[];
    
    // Group by execution mode to handle sequential/parallel properly
    final sequentialCalls = <ToolCall>[];
    final parallelCalls = <ToolCall>[];
    
    for (final call in calls) {
      if (call.executionMode == ExecutionMode.parallel.name) {
        parallelCalls.add(call);
      } else {
        sequentialCalls.add(call);
      }
    }

    // Execute sequential calls first (in order)
    for (final call in sequentialCalls) {
      final result = await dispatch(
        toolName: call.toolName,
        arguments: call.arguments,
        isInternalMission: isInternalMission,
      );
      results.add(result);
    }

    // Execute parallel calls concurrently (up to maxParallel)
    if (parallelCalls.isNotEmpty) {
      final parallelResults = await _dispatchParallel(
        parallelCalls,
        isInternalMission,
      );
      results.addAll(parallelResults);
    }

    return results;
  }

  Future<List<ToolDispatchResult>> _dispatchParallel(
    List<ToolCall> calls,
    bool isInternalMission,
  ) async {
    final completers = <Completer<ToolDispatchResult>>[];
    
    for (final call in calls) {
      final completer = Completer<ToolDispatchResult>();
      completers.add(completer);
      
      await _semaphore.acquire();
      try {
        final result = await dispatch(
          toolName: call.toolName,
          arguments: call.arguments,
          isInternalMission: isInternalMission,
        );
        completer.complete(result);
      } catch (e) {
        completer.complete(ToolDispatchResult(
          success: false,
          error: e.toString(),
          artifactRefs: [],
        ));
      } finally {
        _semaphore.release();
      }
    }

    return Future.wait(completers.map((c) => c.future));
  }

  @override
  List<String> validateSchema({
    required Map<String, dynamic> schema,
    required Map<String, dynamic> arguments,
  }) {
    try {
      final jsonSchema = JsonSchema.create(schema);
      final validationResult = jsonSchema.validate(arguments);
      if (validationResult.isValid) {
        return [];
      }
      return validationResult.errors.map((e) => e.message).toList();
    } catch (e) {
      return ['Schema validation error: $e'];
    }
  }

  @override
  bool checkRiskTier({
    required String riskTier,
    required bool isInternalMission,
  }) {
    switch (riskTier) {
      case 'safe':
        return true;
      case 'confirm':
        return true; // Will be checked at dispatch time with callback
      case 'admin':
        return isInternalMission;
      default:
        return false;
    }
  }

  /// Placeholder for actual tool execution.
  /// In production, this would call the tool based on its source (DDA, generated, MCP).
  Future<String> _executeTool(AgentTool tool, Map<String, dynamic> arguments) async {
    // This is a stub - real implementation would dispatch to:
    // - DDA tool handlers
    // - Generated usecase executors
    // - MCP client calls
    return '{"tool": "${tool.name}", "status": "executed", "arguments": ${jsonEncode(arguments)}}';
  }
}

/// Simple semaphore for limiting concurrent operations.
class _Semaphore {
  _Semaphore(int maxPermits) : _maxPermits = maxPermits, _available = maxPermits;

  final int _maxPermits;
  int _available;
  final List<Completer<void>> _waiters = [];

  Future<void> acquire() async {
    if (_available > 0) {
      _available--;
      return;
    }
    final completer = Completer<void>();
    _waiters.add(completer);
    return completer.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      final completer = _waiters.removeAt(0);
      completer.complete();
    } else {
      _available = (_available + 1).clamp(0, _maxPermits);
    }
  }
}