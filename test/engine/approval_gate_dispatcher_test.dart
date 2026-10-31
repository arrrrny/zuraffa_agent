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
//
// Issue arrrrny/zuraffa_agent#4 (R3 / spec-003 A4 + A5) — the two dispatch
// decisions the audit found untested anywhere are pinned here:
//
//   - A4: the gate AWAITS the approval callback and enforces the declared
//     approval budget — a callback that never answers times out into a
//     denied ToolDispatchResult (the tool never runs); a slow-but-in-budget
//     callback is awaited, not raced away.
//   - A5: an admin-tier tool on a NON-internal mission is denied before the
//     approval surface is even consulted and without invoking the tool
//     implementation — a non-internal mission carries no admin grant (spec
//     034: "The engine refuses to dispatch admin tools when no admin grant
//     is present"; the same policy the sub-agent runtime enforces as
//     `refusedRiskTier`). Admin tools on an INTERNAL mission keep the
//     normal approval-callback flow.

import 'dart:async';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/agent_tool/agent_tool.dart';
import 'package:zuraffa_agent/src/domain/entities/approval_request/approval_request.dart';
import 'package:zuraffa_agent/src/domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
import 'package:zuraffa_agent/src/engine/approval_callback.dart';
import 'package:zuraffa_agent/src/engine/approval_gate_dispatcher.dart';
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

      // A5 (issue #4): admin tools run only on internal missions — the
      // internal mission is the admin grant. A non-internal mission is
      // denied outright (pinned below), so the approving-callback flow for
      // admin is exercised on an internal mission.
      final result = await dispatcher.dispatch(
        toolName: 'fs.write',
        arguments: arguments,
        isInternalMission: true,
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

  group('ApprovalGateToolDispatcher — approval timeout (spec-003 A4)', () {
    test(
      'a callback that never answers times out into a denied result',
      () async {
        final inner = RecordingDispatcher();
        // The wired callback is the recorder: a throwaway lambda here would
        // make "the surface was consulted" unassertable.
        final requests = <ApprovalRequest>[];
        // A callback that never completes: the gate must enforce the declared
        // budget itself instead of hanging the mission loop forever.
        final gate = ApprovalGateToolDispatcher(
          inner: inner,
          riskTiers: const {'fs.write': RiskTier.confirm},
          approvalCallback: (request) {
            requests.add(request);
            return Completer<bool>().future;
          },
          approvalTimeoutMs: 50,
        );

        final result = await gate.dispatch(
          toolName: 'fs.write',
          arguments: arguments,
          isInternalMission: false,
        );

        expect(result.success, isFalse, reason: 'timeout denies the dispatch');
        expect(result.error, contains('fs.write'));
        expect(result.error, contains('timed out'));
        // The tool never ran, and the surface was consulted exactly once —
        // the timeout is enforced, not used as a shortcut.
        expect(inner.dispatchCount, 0);
        expect(requests, hasLength(1));
        expect(requests.single.toolName, 'fs.write');
        expect(requests.single.timeoutMs, 50);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    test('a slow-but-in-budget callback is awaited, not raced away', () async {
      final inner = RecordingDispatcher();
      final gate = ApprovalGateToolDispatcher(
        inner: inner,
        riskTiers: const {'fs.write': RiskTier.confirm},
        approvalCallback: (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 80));
          return true;
        },
        approvalTimeoutMs: 2000,
      );

      final result = await gate.dispatch(
        toolName: 'fs.write',
        arguments: arguments,
        isInternalMission: false,
      );

      expect(result.success, isTrue, reason: 'within budget → still approves');
      expect(result.result, 'ran:fs.write');
      expect(inner.dispatchCount, 1);
    }, timeout: const Timeout(Duration(seconds: 5)));

    test(
      'an approval timeout refuses the whole batch (all-or-nothing)',
      () async {
        final inner = RecordingDispatcher();
        final requests = <ApprovalRequest>[];
        final gate = ApprovalGateToolDispatcher(
          inner: inner,
          riskTiers: const {
            'fs.read': RiskTier.safe,
            'fs.write': RiskTier.confirm,
          },
          approvalCallback: (request) {
            requests.add(request);
            return Completer<bool>().future;
          },
          approvalTimeoutMs: 50,
        );

        final results = await gate.dispatchBatch(
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

        for (final result in results) {
          expect(result.success, isFalse);
          expect(result.error, contains('timed out'));
        }
        expect(inner.batchCalls, isEmpty, reason: 'nothing was dispatched');
        // Only the gated call reached the surface — once.
        expect(requests, hasLength(1));
        expect(requests.single.toolName, 'fs.write');
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    test(
      'a multi-call batch against a stuck surface costs ONE budget, not N',
      () async {
        final inner = RecordingDispatcher();
        final requests = <ApprovalRequest>[];
        final gate = ApprovalGateToolDispatcher(
          inner: inner,
          riskTiers: const {
            'fs.write': RiskTier.confirm,
            'sql.exec': RiskTier.confirm,
            'shell': RiskTier.confirm,
            'deploy': RiskTier.confirm,
          },
          approvalCallback: (request) {
            requests.add(request);
            return Completer<bool>().future;
          },
          approvalTimeoutMs: 200,
        );

        final clock = Stopwatch()..start();
        final results = await gate.dispatchBatch(
          calls: const [
            ToolCall(
              toolName: 'fs.write',
              arguments: {'path': '/tmp/a.txt'},
              executionMode: 'sequential',
            ),
            ToolCall(
              toolName: 'sql.exec',
              arguments: {'q': 'select 1'},
              executionMode: 'sequential',
            ),
            ToolCall(
              toolName: 'shell',
              arguments: {'cmd': 'ls'},
              executionMode: 'sequential',
            ),
            ToolCall(
              toolName: 'deploy',
              arguments: {'env': 'prod'},
              executionMode: 'sequential',
            ),
          ],
          isInternalMission: false,
        );
        clock.stop();

        expect(results, hasLength(4));
        for (final result in results) {
          expect(result.success, isFalse);
          expect(result.error, contains('timed out'));
        }
        expect(inner.batchCalls, isEmpty, reason: 'nothing was dispatched');
        // Every gated call still reaches the surface (the gate does not skip
        // asking), but they share one budget: the serial worst case would be
        // 4 × 200ms. The margin is deliberately wide so a loaded host cannot
        // turn this into a load assertion.
        expect(requests, hasLength(4));
        expect(
          clock.elapsedMilliseconds,
          lessThan(500),
          reason: 'the pre-approval pass must be bounded by ONE budget',
        );
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  });

  group('ApprovalGateToolDispatcher — admin grant (spec-003 A5, issue #4)', () {
    test('admin tool on a non-internal mission is denied without consulting '
        'the approval surface or the tool', () async {
      final inner = RecordingDispatcher();
      final callback = RecordingApprovalCallback(true);
      final dispatcher = ApprovalGateToolDispatcher(
        inner: inner,
        riskTiers: const {'cluster.delete-namespace': RiskTier.admin},
        approvalCallback: callback.call,
      );

      final result = await dispatcher.dispatch(
        toolName: 'cluster.delete-namespace',
        arguments: arguments,
        isInternalMission: false,
      );

      expect(result.success, isFalse);
      expect(result.error, contains('admin'));
      expect(result.error, contains('grant'));
      // Denied BEFORE the approval surface is consulted…
      expect(
        callback.requests,
        isEmpty,
        reason:
            'a non-internal mission carries no admin grant — the '
            'callback is never asked',
      );
      // …and the tool implementation never ran.
      expect(inner.dispatchCount, 0);
    });

    test(
      'admin tool on an internal mission keeps the approval-callback flow',
      () async {
        final inner = RecordingDispatcher();
        final callback = RecordingApprovalCallback(true);
        final dispatcher = ApprovalGateToolDispatcher(
          inner: inner,
          riskTiers: const {'cluster.delete-namespace': RiskTier.admin},
          approvalCallback: callback.call,
        );

        final result = await dispatcher.dispatch(
          toolName: 'cluster.delete-namespace',
          arguments: arguments,
          isInternalMission: true,
        );

        expect(result.success, isTrue);
        expect(callback.requests, hasLength(1));
        expect(inner.dispatchCount, 1);
      },
    );

    test('a batch containing an admin call on a non-internal mission refuses '
        'everything', () async {
      final inner = RecordingDispatcher();
      final callback = RecordingApprovalCallback(true);
      final dispatcher = ApprovalGateToolDispatcher(
        inner: inner,
        riskTiers: const {
          'fs.read': RiskTier.safe,
          'cluster.delete-namespace': RiskTier.admin,
        },
        approvalCallback: callback.call,
      );

      final results = await dispatcher.dispatchBatch(
        calls: const [
          ToolCall(
            toolName: 'fs.read',
            arguments: {'path': '/tmp/a.txt'},
            executionMode: 'sequential',
          ),
          ToolCall(
            toolName: 'cluster.delete-namespace',
            arguments: arguments,
            executionMode: 'sequential',
          ),
        ],
        isInternalMission: false,
      );

      for (final result in results) {
        expect(result.success, isFalse);
        expect(result.error, contains('admin'));
      }
      expect(
        inner.batchCalls,
        isEmpty,
        reason: 'all-or-nothing: the ungrantable admin call refuses the batch',
      );
      expect(inner.dispatchCount, 0);
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
