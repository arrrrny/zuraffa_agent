// Issue arrrrny/zuraffa_agent#132 — the approval gate records every
// approval decision and every tool invocation that passes through it into
// the audit trail.
//
// Contract pinned here:
//
//   - an approved gated call yields approval.granted (requestId + toolName
//     + argsHash) AND tool.invoked (success + resultHash) — raw arguments
//     and raw results never appear in the entries;
//   - a denied gated call yields approval.denied and NO tool.invoked — the
//     tool never ran;
//   - batch decisions are recorded per call, before execution (the
//     all-or-nothing refusal still leaves the recorded decisions in place —
//     the trail records what happened, not what was intended);
//   - without an AuditLog wired, the gate behaves exactly as before
//     (issue #130 contract unchanged).

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/agent_tool/agent_tool.dart';
import 'package:zuraffa_agent/src/domain/entities/approval_request/approval_request.dart';
import 'package:zuraffa_agent/src/domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
import 'package:zuraffa_agent/src/engine/approval_callback.dart';
import 'package:zuraffa_agent/src/engine/approval_gate_dispatcher.dart';
import 'package:zuraffa_agent/src/engine/tool_dispatcher.dart';
import 'package:zuraffa_agent/src/security/audit_hashing.dart';
import 'package:zuraffa_agent/src/security/audit_log.dart';

import '../security/in_memory_audit_sink.dart';

class RecordingDispatcher implements ToolDispatcher {
  int dispatchCount = 0;
  final List<String> dispatchedTools = [];
  List<ToolCall> batchCalls = [];

  @override
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  }) async {
    dispatchCount++;
    dispatchedTools.add(toolName);
    return ToolDispatchResult(
      success: true,
      result: 'ran:$toolName',
      error: '',
      artifactRefs: const [],
    );
  }

  @override
  Future<List<ToolDispatchResult>> dispatchBatch({
    required List<ToolCall> calls,
    required bool isInternalMission,
  }) async {
    batchCalls = calls;
    return [
      for (final call in calls)
        ToolDispatchResult(
          success: true,
          result: 'ran:${call.toolName}',
          error: '',
          artifactRefs: const [],
        ),
    ];
  }

  @override
  List<String> validateSchema({
    required Map<String, dynamic> schema,
    required Map<String, dynamic> arguments,
  }) => const [];

  @override
  bool checkRiskTier({
    required String riskTier,
    required bool isInternalMission,
  }) => true;
}

/// Records the requests it saw; returns [decision] for every call.
class StubApprovalCallback {
  StubApprovalCallback(this.decision);
  final bool decision;
  final List<ApprovalRequest> requests = [];

  Future<bool> call(ApprovalRequest request) async {
    requests.add(request);
    return decision;
  }
}

void main() {
  late InMemoryAuditSink sink;
  late SinkAuditLog audit;
  late RecordingDispatcher inner;
  late StubApprovalCallback callback;

  setUp(() {
    sink = InMemoryAuditSink();
    audit = SinkAuditLog(sink: sink);
    inner = RecordingDispatcher();
    callback = StubApprovalCallback(true);
  });

  group('ApprovalGateToolDispatcher — audit wiring', () {
    test(
      'an approved gated call records the decision and the invocation',
      () async {
        callback = StubApprovalCallback(true);
        final g = ApprovalGateToolDispatcher(
          inner: inner,
          riskTiers: const {'shell': RiskTier.confirm},
          approvalCallback: callback.call,
          auditLog: audit,
        );

        await g.dispatch(
          toolName: 'shell',
          arguments: {'cmd': 'ls', 'token': 'sekrit'},
          isInternalMission: false,
        );

        expect(
          [for (final e in sink.stored) e.action],
          [AuditActions.approvalGranted, AuditActions.toolInvoked],
        );
        final decision = sink.stored[0];
        expect(decision.details['requestId'], callback.requests.single.id);
        expect(decision.details['toolName'], 'shell');
        expect(
          decision.details['argsHash'],
          auditHash({'cmd': 'ls', 'token': 'sekrit'}),
        );
        final invocation = sink.stored[1];
        expect(invocation.details['toolName'], 'shell');
        expect(invocation.details['success'], true);
        expect(invocation.details['resultHash'], auditHash('ran:shell'));
        // Raw material never reaches the trail.
        final serialized = sink.stored.map((e) => e.toJson().toString()).join();
        expect(serialized.contains('sekrit'), isFalse);
        expect(serialized.contains('ran:shell'), isFalse);
      },
    );

    test('a denied gated call records the denial and no invocation', () async {
      callback = StubApprovalCallback(false);
      final g = ApprovalGateToolDispatcher(
        inner: inner,
        riskTiers: const {'shell': RiskTier.confirm},
        approvalCallback: callback.call,
        auditLog: audit,
      );

      final result = await g.dispatch(
        toolName: 'shell',
        arguments: {'cmd': 'rm -rf /'},
        isInternalMission: false,
      );

      expect(result.success, isFalse);
      expect(inner.dispatchCount, 0, reason: 'the tool never ran');
      expect(
        [for (final e in sink.stored) e.action],
        [AuditActions.approvalDenied],
      );
      expect(
        sink.stored.single.details['argsHash'],
        auditHash({'cmd': 'rm -rf /'}),
      );
    });

    test('safe tools dispatch straight through — an invocation is recorded, '
        'no approval decision exists', () async {
      final g = ApprovalGateToolDispatcher(
        inner: inner,
        riskTiers: const {'safe': RiskTier.safe},
        approvalCallback: callback.call,
        auditLog: audit,
      );

      await g.dispatch(
        toolName: 'safe',
        arguments: {'q': 'x'},
        isInternalMission: false,
      );

      expect(
        callback.requests,
        isEmpty,
        reason: 'the gate never consults the callback for safe tools',
      );
      expect(
        [for (final e in sink.stored) e.action],
        [AuditActions.toolInvoked],
      );
    });

    test('batch calls record one decision each; the invocation follows the '
        'batch', () async {
      final g = ApprovalGateToolDispatcher(
        inner: inner,
        riskTiers: const {'shell': RiskTier.confirm, 'deploy': RiskTier.admin},
        approvalCallback: callback.call,
        auditLog: audit,
      );

      await g.dispatchBatch(
        calls: [
          const ToolCall(
            toolName: 'shell',
            arguments: {'cmd': 'ls'},
            executionMode: 'sequential',
          ),
          const ToolCall(
            toolName: 'deploy',
            arguments: {'env': 'prod'},
            executionMode: 'sequential',
          ),
        ],
        isInternalMission: false,
      );

      expect(
        [for (final e in sink.stored) e.action],
        [
          AuditActions.approvalGranted,
          AuditActions.approvalGranted,
          AuditActions.toolInvoked,
          AuditActions.toolInvoked,
        ],
      );
      expect(
        [for (final e in sink.stored.take(2)) e.details['toolName']],
        ['shell', 'deploy'],
      );
    });

    test(
      'an unwired-callback refusal records nothing (no decision was made)',
      () async {
        final g = ApprovalGateToolDispatcher(
          inner: inner,
          riskTiers: const {'deploy': RiskTier.admin},
          auditLog: audit,
        );

        final results = await g.dispatchBatch(
          calls: [
            const ToolCall(
              toolName: 'deploy',
              arguments: {'env': 'prod'},
              executionMode: 'sequential',
            ),
          ],
          isInternalMission: false,
        );

        expect(results.single.success, isFalse);
        expect(sink.stored, isEmpty);
      },
    );

    test(
      'a throwing audit sink never fails the dispatch (issue #132 review fix)',
      () async {
        final g = ApprovalGateToolDispatcher(
          inner: inner,
          riskTiers: const {'shell': RiskTier.confirm},
          approvalCallback: callback.call,
          auditLog: SinkAuditLog(sink: ThrowingAuditSink()),
        );

        final result = await g.dispatch(
          toolName: 'shell',
          arguments: {'cmd': 'ls'},
          isInternalMission: false,
        );

        expect(result.success, isTrue);
        expect(result.result, 'ran:shell');
        // Pump the fire-and-forget audit futures: pre-fix, their sink
        // errors reached the zone uncaught-error handler here and failed
        // this run; the gate must stay ignorant of audit-backend failures.
        await Future<void>.delayed(Duration.zero);
      },
    );
  });
}
