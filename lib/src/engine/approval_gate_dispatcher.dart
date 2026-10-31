// HAND-CURATED — issue arrrrny/zuraffa_agent#130 (AC: "Wire spec 034 risk
// tiers into ToolDispatcher — high-risk tools require approval_callback").
//
// ApprovalGateToolDispatcher — a ToolDispatcher decorator that enforces the
// spec 034 (agent-tool-risk-tier) risk classification at the dispatch
// boundary. Mirrors the OversizedResultPolicyDispatcher decorator shape
// (which itself mirrors AllowlistToolDispatcher).
//
// Spec 034 gives every AgentTool a RiskTier — safe | confirm | admin — and
// RiskTier.requiresConfirmation marks confirm + admin as the tiers the
// engine must gate before the tool runs. The approval surface already
// existed (ApprovalCallback typedef, defaultApprovalCallback always-deny,
// ApprovalRequest entity) but nothing in the dispatcher layer consumed it;
// this decorator is the wiring:
//
//   - safe or unclassified tools dispatch straight through; the gate never
//     consults (or requires) a callback.
//   - confirm/admin tools require an ApprovalCallback: without one wired,
//     the dispatch is refused fail-closed with a typed failure BEFORE the
//     tool implementation runs (an unwired high-risk tool must never fall
//     through — silent under-classification is the failure mode spec 034's
//     typed ArgumentError exists to prevent). With one wired, the callback
//     receives the ApprovalRequest and its decision rules: deny refuses,
//     approve dispatches.
//   - dispatchBatch is all-or-nothing: the gate approves every high-risk
//     call first; one unapproved call refuses the entire batch and the
//     inner batch never runs. Approve-then-execute, never the reverse.
//   - validateSchema / checkRiskTier delegate to the inner dispatcher.

import 'dart:async';

import 'package:uuid/uuid.dart';

import '../domain/entities/agent_tool/agent_tool.dart';
import '../domain/entities/approval_request/approval_request.dart';
import '../domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
import '../security/audit_log.dart';
import 'approval_callback.dart';
import 'tool_dispatcher.dart';

/// Tool dispatcher decorator enforcing spec 034 risk tiers: high-risk
/// tools (`RiskTier.confirm` / `RiskTier.admin`) require an
/// [ApprovalCallback] wired on this gate or their dispatch is refused
/// before the tool runs.
class ApprovalGateToolDispatcher implements ToolDispatcher {
  ApprovalGateToolDispatcher({
    required ToolDispatcher inner,
    required Map<String, RiskTier> riskTiers,
    ApprovalCallback? approvalCallback,
    DateTime Function()? clock,
    this.approvalTimeoutMs = defaultApprovalTimeoutMs,
    this.auditLog,
  }) : _inner = inner,
       _riskTiers = Map.unmodifiable(riskTiers),
       _approvalCallback = approvalCallback,
       _clock = clock ?? DateTime.now;

  /// Default approval budget carried on every [ApprovalRequest] (ms). The
  /// approval surface consuming the request owns enforcing it; the gate
  /// only declares the budget the requester allows.
  static const int defaultApprovalTimeoutMs = 30000;

  final ToolDispatcher _inner;

  /// Tool id → spec 034 risk tier. Tools absent from the map are
  /// unclassified: the gate leaves them to the inner dispatcher (the
  /// registry owns unknown-tool errors), so the gate never invents a tier.
  final Map<String, RiskTier> _riskTiers;

  final ApprovalCallback? _approvalCallback;
  final DateTime Function() _clock;
  final int approvalTimeoutMs;

  /// Optional audit seam (issue #132): every approval decision that reaches
  /// the callback and every tool invocation that passes through this
  /// dispatcher is appended to the security audit trail — decisions as
  /// `approval.granted` / `approval.denied`, invocations as
  /// `tool.invoked` (name + args/result hashes, never payloads). No-op
  /// without an injection.
  final AuditLog? auditLog;

  final Uuid _uuid = const Uuid();

  @override
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  }) async {
    final tier = _riskTiers[toolName];
    if (tier == null || !tier.requiresConfirmation) {
      final result = await _inner.dispatch(
        toolName: toolName,
        arguments: arguments,
        isInternalMission: isInternalMission,
      );
      _auditInvocation(toolName, arguments, result);
      return result;
    }
    final callback = _approvalCallback;
    if (callback == null) {
      return _refusal(
        'high-risk tool "$toolName" is riskTier=${tier.name} and requires '
        'an approval callback before dispatch; none is wired — dispatch '
        'refused fail-closed (spec 034 / issue #130)',
      );
    }
    final request = _buildRequest(toolName: toolName, arguments: arguments);
    final approved = await callback(request);
    _auditDecision(request: request, approved: approved);
    if (!approved) {
      return _refusal(
        'dispatch of "$toolName" (riskTier=${tier.name}) denied by the '
        'approval callback — tool not executed (spec 034 / issue #130)',
      );
    }
    final result = await _inner.dispatch(
      toolName: toolName,
      arguments: arguments,
      isInternalMission: isInternalMission,
    );
    _auditInvocation(toolName, arguments, result);
    return result;
  }

  @override
  Future<List<ToolDispatchResult>> dispatchBatch({
    required List<ToolCall> calls,
    required bool isInternalMission,
  }) async {
    // Approve-then-execute: every high-risk call is gated first; one
    // unapproved call refuses the whole batch (all-or-nothing — a batch
    // must never run partially gated).
    final unapproved = <String>[];
    for (final call in calls) {
      final tier = _riskTiers[call.toolName];
      if (tier == null || !tier.requiresConfirmation) continue;
      final callback = _approvalCallback;
      if (callback == null) {
        unapproved.add(call.toolName);
        continue;
      }
      final request = _buildRequest(
        toolName: call.toolName,
        arguments: call.arguments,
      );
      final approved = await callback(request);
      _auditDecision(request: request, approved: approved);
      if (!approved) unapproved.add(call.toolName);
    }
    if (unapproved.isNotEmpty) {
      final result = _refusal(
        'approval gate refused the batch: call(s) $unapproved require an '
        'approval callback that is not wired or was denied — nothing was '
        'dispatched (all-or-nothing, spec 034 / issue #130)',
      );
      return List.filled(calls.length, result);
    }
    final results = await _inner.dispatchBatch(
      calls: calls,
      isInternalMission: isInternalMission,
    );
    for (var i = 0; i < calls.length && i < results.length; i++) {
      _auditInvocation(calls[i].toolName, calls[i].arguments, results[i]);
    }
    return results;
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

  ApprovalRequest _buildRequest({
    required String toolName,
    required Map<String, dynamic> arguments,
  }) => ApprovalRequest(
    id: _uuid.v4(),
    toolName: toolName,
    arguments: Map<String, dynamic>.unmodifiable(arguments),
    requestedAt: _clock(),
    timeoutMs: approvalTimeoutMs,
  );

  /// Appends one `approval.granted` / `approval.denied` entry (issue #132).
  /// Fire-and-forget: the gate never waits on the audit sink.
  void _auditDecision({
    required ApprovalRequest request,
    required bool approved,
  }) {
    final audit = auditLog;
    if (audit == null) return;
    unawaited(
      audit.approvalDecision(
        requestId: request.id,
        toolName: request.toolName,
        arguments: request.arguments,
        approved: approved,
      ),
    );
  }

  /// Appends one `tool.invoked` entry (issue #132) — name + args/result
  /// hashes only. Fire-and-forget.
  void _auditInvocation(
    String toolName,
    Map<String, dynamic> arguments,
    ToolDispatchResult result,
  ) {
    final audit = auditLog;
    if (audit == null) return;
    unawaited(
      audit.toolCallInvoked(
        toolName: toolName,
        arguments: arguments,
        result: result.result,
        success: result.success,
      ),
    );
  }

  /// The typed refusal shape: a failed ToolDispatchResult whose transcript
  ///-safe error names the tool, the tier and the reason. The tool
  /// implementation never ran.
  ToolDispatchResult _refusal(String message) => ToolDispatchResult(
    success: false,
    result: '',
    error: message,
    artifactRefs: const [],
  );
}
