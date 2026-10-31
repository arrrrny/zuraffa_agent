// HAND-CURATED — DO NOT REGENERATE VIA zfa.
//
// ExecutionModeToolDispatcher — the batch seam that honors each
// ToolCall.executionMode (issue arrrrny/zuraffa_agent#4, R3.1: "sequential/
// parallel execution modes"; spec-003 acceptance A3: "parallel batch runs
// concurrently, results collected in call order").
//
// Until this file every shipped dispatchBatch ran strictly one-at-a-time
// (AllowlistToolDispatcher and MemoryToolDispatcher are `for ... await`
// loops; the gate and oversized decorators delegate) — the parallel mode
// existed only as an enum string. Contract:
//
//   - contiguous runs of 'parallel' calls dispatch CONCURRENTLY
//     (Future.wait over the inner dispatcher);
//   - contiguous runs of anything else dispatch one at a time, in call
//     order (the ToolCall doc pins the two mode strings; unknown mode
//     strings fall back to the safe sequential reading rather than invent
//     a new failure mode mid-batch);
//   - results are reassembled POSITIONALLY — results[i] is always the
//     outcome of calls[i], regardless of completion order;
//   - dispatch / validateSchema / checkRiskTier delegate untouched, so the
//     decorator composes with OversizedResultPolicyDispatcher in either
//     order (that one is a pure per-call transform).
//
//   - ORDER MATTERS WITH ApprovalGateToolDispatcher: this decorator must be
//     the INNER one (`ApprovalGate(inner: ExecutionMode(inner: …))`). Wrapped
//     the other way round, this dispatchBatch calls `_inner.dispatch` per
//     call, so the gate's all-or-nothing pre-approval pass never runs — a
//     batch of [safe-tool, confirm-tool-that-gets-denied] would then execute
//     the safe tool and refuse only the second, the exact partial-batch
//     gating the gate exists to prevent. The inverted wiring is rejected at
//     construction time rather than left to the first host that follows a
//     stale doc claim (issue #4 review).
//
// The unknown-executionMode fallback is sequential ON PURPOSE, and differs
// from `RiskTier.fromString` (which throws on an unknown tier): an unknown
// tier would silently downgrade a security classification, while an unknown
// execution mode only costs concurrency. The safe reading of a mode string
// this file does not recognize is "run it in order".
//
// Not exported from lib/zuraffa_agent.dart — consistent with the sibling
// engine runtimes (mission_runner.dart, tool_dispatcher.dart).

import '../domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
import 'approval_gate_dispatcher.dart';
import 'tool_dispatcher.dart';

/// The execution mode tool dispatcher.
class ExecutionModeToolDispatcher implements ToolDispatcher {
  /// Creates an execution mode tool dispatcher.
  ExecutionModeToolDispatcher({required ToolDispatcher inner})
    : _inner = inner {
    // Fail loud instead of mis-gating (see the header): with this decorator
    // outside the gate, dispatchBatch bypasses the gate's all-or-nothing
    // pre-approval pass and a mid-batch denial leaves earlier calls already
    // executed.
    if (inner is ApprovalGateToolDispatcher) {
      throw ArgumentError.value(
        inner,
        'inner',
        'ExecutionModeToolDispatcher must not wrap an '
            'ApprovalGateToolDispatcher — the gate must be OUTERMOST '
            '(ApprovalGate(inner: ExecutionMode(inner: …))): the inverted '
            'order silently downgrades batch gating to per-call gating '
            '(spec 034 / issue #4)',
      );
    }
  }

  final ToolDispatcher _inner;

  @override
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  }) => _inner.dispatch(
    toolName: toolName,
    arguments: arguments,
    isInternalMission: isInternalMission,
  );

  @override
  Future<List<ToolDispatchResult>> dispatchBatch({
    required List<ToolCall> calls,
    required bool isInternalMission,
  }) async {
    // Positional slots: filled by mode-run below, so every slot is set
    // exactly once before the return.
    final slots = List<ToolDispatchResult?>.filled(calls.length, null);
    var i = 0;
    while (i < calls.length) {
      final mode = calls[i].executionMode;
      var end = i;
      while (end < calls.length && calls[end].executionMode == mode) {
        end++;
      }
      final run = calls.sublist(i, end);
      if (mode == 'parallel') {
        final runResults = await Future.wait([
          for (final call in run)
            _inner.dispatch(
              toolName: call.toolName,
              arguments: call.arguments,
              isInternalMission: isInternalMission,
            ),
        ]);
        for (var k = 0; k < runResults.length; k++) {
          slots[i + k] = runResults[k];
        }
      } else {
        for (var k = 0; k < run.length; k++) {
          final call = run[k];
          slots[i + k] = await _inner.dispatch(
            toolName: call.toolName,
            arguments: call.arguments,
            isInternalMission: isInternalMission,
          );
        }
      }
      i = end;
    }
    return [for (final slot in slots) slot!];
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
