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

import 'dart:async';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/agent_tool/agent_tool.dart';
import 'package:zuraffa_agent/src/domain/entities/approval_request/approval_request.dart';
import 'package:zuraffa_agent/src/domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
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

      // A5 (issue #4): admin tools run only on internal missions — the
      // internal mission is the admin grant — so this batch dispatches on
      // an internal mission to exercise the admin approval path.
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
        isInternalMission: true,
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
          // `confirm`, not `admin`: an admin call on a non-internal mission
          // IS a decision and is audited (see the admin-grant tests below).
          riskTiers: const {'deploy': RiskTier.confirm},
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
    test(
      'an admin grant refusal records approval.denied (issue #4 review)',
      () async {
        final g = ApprovalGateToolDispatcher(
          inner: inner,
          riskTiers: const {'cluster.delete-namespace': RiskTier.admin},
          approvalCallback: callback.call,
          auditLog: audit,
        );

        final result = await g.dispatch(
          toolName: 'cluster.delete-namespace',
          arguments: {'ns': 'prod'},
          isInternalMission: false,
        );
        await Future<void>.delayed(Duration.zero);

        expect(result.success, isFalse);
        expect(
          callback.requests,
          isEmpty,
          reason: 'the surface is never consulted without a grant',
        );
        expect(inner.dispatchCount, 0, reason: 'the tool never ran');
        // The highest-severity denial of all must be the MOST visible event
        // in the trail, not the only invisible one.
        expect(
          [for (final e in sink.stored) e.action],
          [AuditActions.approvalDenied],
        );
        expect(
          sink.stored.single.details['toolName'],
          'cluster.delete-namespace',
        );
        expect(
          sink.stored.single.details['argsHash'],
          auditHash({'ns': 'prod'}),
        );
      },
    );

    test('a batch admin-grant refusal records one denial per blocked call '
        'and no invocation', () async {
      final g = ApprovalGateToolDispatcher(
        inner: inner,
        riskTiers: const {
          'fs.read': RiskTier.safe,
          'cluster.delete-namespace': RiskTier.admin,
        },
        approvalCallback: callback.call,
        auditLog: audit,
      );

      final results = await g.dispatchBatch(
        calls: [
          const ToolCall(
            toolName: 'fs.read',
            arguments: {'path': '/tmp/a.txt'},
            executionMode: 'sequential',
          ),
          const ToolCall(
            toolName: 'cluster.delete-namespace',
            arguments: {'ns': 'prod'},
            executionMode: 'sequential',
          ),
        ],
        isInternalMission: false,
      );
      await Future<void>.delayed(Duration.zero);

      expect(results.every((r) => !r.success), isTrue);
      expect(inner.batchCalls, isEmpty);
      expect(
        [for (final e in sink.stored) e.action],
        [AuditActions.approvalDenied],
        reason: 'the blocked admin attempt is in the trail; nothing ran',
      );
      expect(
        sink.stored.single.details['toolName'],
        'cluster.delete-namespace',
      );
    });

    test(
      'an approval timeout is audited as approval.denied (spec-003 A4)',
      () async {
        final g = ApprovalGateToolDispatcher(
          inner: inner,
          riskTiers: const {'shell': RiskTier.confirm},
          approvalCallback: (_) => Completer<bool>().future,
          approvalTimeoutMs: 20,
          auditLog: audit,
        );

        final result = await g.dispatch(
          toolName: 'shell',
          arguments: {'cmd': 'ls'},
          isInternalMission: false,
        );
        await Future<void>.delayed(Duration.zero);

        expect(result.success, isFalse);
        expect(result.error, contains('timed out'));
        expect(inner.dispatchCount, 0);
        // The dispatch outcome IS a denial, whatever the surface failed to
        // answer — so the trail says so.
        expect(
          [for (final e in sink.stored) e.action],
          [AuditActions.approvalDenied],
        );
        expect(
          sink.stored.single.details['argsHash'],
          auditHash({'cmd': 'ls'}),
        );
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );
  });
}
