// Issue arrrrny/zuraffa_agent#130 (AC: "Wire spec 034 risk tiers into
// ToolDispatcher — high-risk tools require approval_callback").
//
// Spec 034 gives every AgentTool a RiskTier (safe|confirm|admin) whose
// requiresConfirmation getter marks confirm+admin as the tiers the engine
// must gate. The approval surface (ApprovalCallback typedef,
// defaultApprovalCallback always-deny, ApprovalRequest entity) already
// exists but nothing in the dispatcher layer consumes it — the gate below
// is the wiring. Contract pinned here:
//
//   - safe / unclassified tools dispatch straight through; no callback
//     is consulted and none is required.
//   - confirm/admin tools without a wired ApprovalCallback are refused
//     with a typed failure BEFORE the tool runs — the inner dispatcher
//     never sees the call. An unwired high-risk tool is the exact
//     under-classification failure mode spec 034's typed ArgumentError
//     exists to prevent; the gate refuses fail-closed.
//   - confirm/admin tools with a callback: the callback receives the
//     ApprovalRequest (toolName + arguments + timeoutMs) and its decision
//     rules — deny refuses, approve dispatches.
//   - dispatchBatch is all-or-nothing: one gated call the batch cannot
//     approve refuses the entire batch; the inner batch never runs.
//   - validateSchema / checkRiskTier delegate to the inner dispatcher.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/agent_tool/agent_tool.dart';
import 'package:zuraffa_agent/src/domain/entities/approval_request/approval_request.dart';
import 'package:zuraffa_agent/src/domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
import 'package:zuraffa_agent/src/engine/approval_gate_dispatcher.dart';
import 'package:zuraffa_agent/src/engine/approval_callback.dart';
import 'package:zuraffa_agent/src/engine/tool_dispatcher.dart';

/// Inner dispatcher that records every call it sees — assertions on
/// `dispatchCount`/`batchCalls` prove gated calls never reach the tool.
class RecordingDispatcher implements ToolDispatcher {
  int dispatchCount = 0;
  final List<String> dispatchedTools = [];
  final List<Map<String, dynamic>> dispatchedArguments = [];
  List<ToolCall> batchCalls = [];

  @override
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  }) async {
    dispatchCount++;
    dispatchedTools.add(toolName);
    dispatchedArguments.add(arguments);
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
    return List.generate(
      calls.length,
      (i) => ToolDispatchResult(
        success: true,
        result: 'ran:${calls[i].toolName}',
        error: '',
        artifactRefs: const [],
      ),
    );
  }

  @override
  List<String> validateSchema({
    required Map<String, dynamic> schema,
    required Map<String, dynamic> arguments,
  }) => const ['schema-error-from-inner'];

  @override
  bool checkRiskTier({
    required String riskTier,
    required bool isInternalMission,
  }) => riskTier == 'safe' || isInternalMission;
}

/// Approval callback that records the requests it receives and returns a
/// fixed decision.
class RecordingApprovalCallback {
  RecordingApprovalCallback(this.decision);

  final bool decision;
  final List<ApprovalRequest> requests = [];

  Future<bool> call(ApprovalRequest request) async {
    requests.add(request);
    return decision;
  }
}

void main() {
  const arguments = {'path': '/tmp/report.txt', 'content': 'hello'};

  group('ApprovalGateToolDispatcher — safe and unclassified tools', () {
    test('safe-tier tool dispatches without any approval callback', () async {
      final inner = RecordingDispatcher();
      final dispatcher = ApprovalGateToolDispatcher(
        inner: inner,
        riskTiers: const {'fs.read': RiskTier.safe},
      );

      final result = await dispatcher.dispatch(
        toolName: 'fs.read',
        arguments: arguments,
        isInternalMission: false,
      );

      expect(result.success, isTrue);
      expect(result.result, 'ran:fs.read');
      expect(inner.dispatchCount, 1);
      expect(inner.dispatchedTools, ['fs.read']);
      expect(inner.dispatchedArguments, [arguments]);
    });

    test('tool absent from the tier map is not gated', () async {
      final inner = RecordingDispatcher();
      final dispatcher = ApprovalGateToolDispatcher(
        inner: inner,
        riskTiers: const {'fs.read': RiskTier.safe},
      );

      final result = await dispatcher.dispatch(
        toolName: 'mcp.unknown-tool',
        arguments: arguments,
        isInternalMission: false,
      );

      expect(result.success, isTrue);
      expect(inner.dispatchCount, 1);
    });
  });

  group('ApprovalGateToolDispatcher — high-risk tools require approval', () {
    test('confirm-tier tool with no callback wired is refused', () async {
      final inner = RecordingDispatcher();
      final dispatcher = ApprovalGateToolDispatcher(
        inner: inner,
        riskTiers: const {'fs.write': RiskTier.confirm},
      );

      final result = await dispatcher.dispatch(
        toolName: 'fs.write',
        arguments: arguments,
        isInternalMission: false,
      );

      expect(result.success, isFalse, reason: 'fail-closed: no callback wired');
      expect(result.result, isEmpty);
      expect(result.error, contains('fs.write'));
      expect(result.error, contains('confirm'));
      expect(result.error, contains('approval'));
      // The gated call must never reach the tool implementation.
      expect(inner.dispatchCount, 0);
    });

    test('admin-tier tool with no callback wired is refused', () async {
      final inner = RecordingDispatcher();
      final dispatcher = ApprovalGateToolDispatcher(
        inner: inner,
        riskTiers: const {'cluster.delete-namespace': RiskTier.admin},
      );

      final result = await dispatcher.dispatch(
        toolName: 'cluster.delete-namespace',
        arguments: arguments,
        isInternalMission: false,
      );

      expect(result.success, isFalse);
      expect(result.error, contains('admin'));
      expect(inner.dispatchCount, 0);
    });

    test('denying callback blocks the dispatch', () async {
      final inner = RecordingDispatcher();
      final callback = RecordingApprovalCallback(false);
      final dispatcher = ApprovalGateToolDispatcher(
        inner: inner,
        riskTiers: const {'fs.write': RiskTier.confirm},
        approvalCallback: callback.call,
      );

      final result = await dispatcher.dispatch(
        toolName: 'fs.write',
        arguments: arguments,
        isInternalMission: false,
      );

      expect(result.success, isFalse);
      expect(result.error, contains('fs.write'));
      expect(callback.requests, hasLength(1));
      expect(inner.dispatchCount, 0);
    });

    test('approving callback lets the dispatch through and receives the '
        'request', () async {
      final inner = RecordingDispatcher();
      final callback = RecordingApprovalCallback(true);
      final fixedClock = DateTime.utc(2026, 10, 31, 9, 30);
      final dispatcher = ApprovalGateToolDispatcher(
        inner: inner,
        riskTiers: const {'fs.write': RiskTier.confirm},
        approvalCallback: callback.call,
        clock: () => fixedClock,
      );

      final result = await dispatcher.dispatch(
        toolName: 'fs.write',
        arguments: arguments,
        isInternalMission: false,
      );

      expect(result.success, isTrue);
      expect(result.result, 'ran:fs.write');
      expect(inner.dispatchCount, 1);
      expect(inner.dispatchedTools, ['fs.write']);
      expect(inner.dispatchedArguments, [arguments]);

      final request = callback.requests.single;
      expect(request.toolName, 'fs.write');
      expect(request.arguments, arguments);
      expect(request.requestedAt, fixedClock);
      expect(request.id, isNotEmpty);
      expect(request.timeoutMs, greaterThan(0));
    });

    test('dispatch result of an approved call is the inner result', () async {
      final inner = RecordingDispatcher();
      final dispatcher = ApprovalGateToolDispatcher(
        inner: inner,
        riskTiers: const {'fs.write': RiskTier.admin},
        approvalCallback: RecordingApprovalCallback(true).call,
      );

      final result = await dispatcher.dispatch(
        toolName: 'fs.write',
        arguments: arguments,
        isInternalMission: false,
      );

      expect(result.success, isTrue);
      expect(result.result, 'ran:fs.write');
    });

    test('always-deny default callback blocks an unwired high-risk tool '
        '(defense in depth)', () async {
      final inner = RecordingDispatcher();
      final callback = RecordingApprovalCallback(false);
      final dispatcher = ApprovalGateToolDispatcher(
        inner: inner,
        riskTiers: const {'fs.write': RiskTier.confirm},
        // The library's own safe default: defaultApprovalCallback denies.
        approvalCallback: defaultApprovalCallback,
      );

      final result = await dispatcher.dispatch(
        toolName: 'fs.write',
        arguments: arguments,
        isInternalMission: false,
      );

      expect(result.success, isFalse);
      expect(inner.dispatchCount, 0);
      expect(callback.requests, isEmpty);
    });
  });

  group('ApprovalGateToolDispatcher — dispatchBatch is all-or-nothing', () {
    test('one gated call with no callback refuses the whole batch', () async {
      final inner = RecordingDispatcher();
      final dispatcher = ApprovalGateToolDispatcher(
        inner: inner,
        riskTiers: const {
          'fs.read': RiskTier.safe,
          'fs.write': RiskTier.confirm,
        },
      );

      final results = await dispatcher.dispatchBatch(
        calls: const [
          ToolCall(
            toolName: 'fs.read',
            arguments: {'path': '/tmp/a.txt'},
            executionMode: 'sequential',
          ),
          ToolCall(
            toolName: 'fs.write',
            arguments: arguments,
            executionMode: 'sequential',
          ),
        ],
        isInternalMission: false,
      );

      // Positional refusal results, one per call.
      expect(results, hasLength(2));
      for (final result in results) {
        expect(result.success, isFalse);
        expect(result.error, contains('fs.write'));
        expect(result.error, contains('approval'));
      }
      expect(inner.batchCalls, isEmpty, reason: 'batch must not run at all');
      expect(inner.dispatchCount, 0);
    });

    test('all-safe batch passes through to the inner batch', () async {
      final inner = RecordingDispatcher();
      final dispatcher = ApprovalGateToolDispatcher(
        inner: inner,
        riskTiers: const {
          'fs.read': RiskTier.safe,
          'web.search': RiskTier.safe,
        },
      );

      final results = await dispatcher.dispatchBatch(
        calls: const [
          ToolCall(
            toolName: 'fs.read',
            arguments: {'path': '/tmp/a.txt'},
            executionMode: 'sequential',
          ),
          ToolCall(
            toolName: 'web.search',
            arguments: {'q': 'zuraffa'},
            executionMode: 'parallel',
          ),
        ],
        isInternalMission: false,
      );

      expect(results, hasLength(2));
      expect(results.every((r) => r.success), isTrue);
      expect(inner.batchCalls, hasLength(2));
      expect(inner.batchCalls.map((c) => c.toolName).toList(), [
        'fs.read',
        'web.search',
      ]);
    });

    test(
      'batch where the high-risk call is approved runs the inner batch',
      () async {
        final inner = RecordingDispatcher();
        final dispatcher = ApprovalGateToolDispatcher(
          inner: inner,
          riskTiers: const {'fs.write': RiskTier.confirm},
          approvalCallback: RecordingApprovalCallback(true).call,
        );

        final results = await dispatcher.dispatchBatch(
          calls: const [
            ToolCall(
              toolName: 'fs.write',
              arguments: arguments,
              executionMode: 'sequential',
            ),
          ],
          isInternalMission: false,
        );

        expect(results, hasLength(1));
        expect(results.single.success, isTrue);
        expect(inner.batchCalls, hasLength(1));
      },
    );
  });

  group('ApprovalGateToolDispatcher — delegation', () {
    test(
      'validateSchema and checkRiskTier delegate to the inner dispatcher',
      () {
        final inner = RecordingDispatcher();
        final dispatcher = ApprovalGateToolDispatcher(
          inner: inner,
          riskTiers: const {'fs.write': RiskTier.confirm},
        );

        expect(
          dispatcher.validateSchema(schema: const {}, arguments: arguments),
          ['schema-error-from-inner'],
        );
        expect(
          dispatcher.checkRiskTier(riskTier: 'safe', isInternalMission: false),
          isTrue,
        );
        expect(
          dispatcher.checkRiskTier(riskTier: 'admin', isInternalMission: false),
          isFalse,
        );
      },
    );
  });

  group('ApprovalGateToolDispatcher — refusal shape', () {
    test('refusal is a typed failure the transcript can relay', () async {
      final inner = RecordingDispatcher();
      final dispatcher = ApprovalGateToolDispatcher(
        inner: inner,
        riskTiers: const {'fs.write': RiskTier.confirm},
      );

      final result = await dispatcher.dispatch(
        toolName: 'fs.write',
        arguments: arguments,
        isInternalMission: false,
      );

      expect(result.success, isFalse);
      expect(result.result, isEmpty);
      expect(result.error, isNotEmpty);
      expect(result.artifactRefs, isEmpty);
    });
  });
}
