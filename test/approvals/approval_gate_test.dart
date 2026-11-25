// ApprovalGate tests (FR-004, SC-004, SC-005, SC-011,
// contracts/approval-gate.md).
//
// The wrapper-owned gate presents through the host AgentApprovalPort and
// returns grant/deny/expired; a missing port yields missingApprovalPort; the
// durable surface (pi#12) returns durableUnavailable. No model egress happens
// while the gate is open (the beforeTool hook does not call the tool).
import 'package:test/test.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

void main() {
  group('ApprovalGate', () {
    final req = ApprovalRequest(
      toolName: 'deploy',
      tier: RiskTier.high,
      deadline: const Duration(seconds: 5),
      args: const {'env': 'prod'},
    );

    test('a grant yields ApprovalGranted', () async {
      final port = InMemoryAgentApprovalPort();
      final gate = ApprovalGate(port: port);
      final outcome = await gate.request(req);
      expect(outcome, isA<ApprovalGranted>());
      expect(port.requests.single.prompt, contains('deploy'));
    });

    test('a deny yields ApprovalDenied', () async {
      final port = InMemoryAgentApprovalPort(decision: ApprovalDecision.denied);
      final gate = ApprovalGate(port: port);
      final outcome = await gate.request(req);
      expect(outcome, isA<ApprovalDenied>());
    });

    test(
      'a timeout past the memoized deadline yields ApprovalExpired',
      () async {
        final port = _SlowApprovalPort(const Duration(seconds: 30));
        final gate = ApprovalGate(port: port);
        final outcome = await gate.request(
          ApprovalRequest(
            toolName: 'deploy',
            tier: RiskTier.high,
            deadline: const Duration(milliseconds: 10),
          ),
        );
        expect(outcome, isA<ApprovalExpired>());
      },
    );

    test('a missing port yields MissingApprovalPort', () async {
      final gate = ApprovalGate(port: null);
      final outcome = await gate.request(req);
      expect(outcome, isA<MissingApprovalPort>());
    });

    test('the durable surface returns DurableUnavailable pre-pi#12', () async {
      final port = InMemoryAgentApprovalPort();
      final gate = ApprovalGate(port: port, durable: true);
      final outcome = await gate.request(req);
      expect(outcome, isA<DurableUnavailable>());
      expect(port.requests, isEmpty);
    });
  });
}

/// An [AgentApprovalPort] that answers only after [delay].
class _SlowApprovalPort implements AgentApprovalPort {
  final Duration delay;
  _SlowApprovalPort(this.delay);

  @override
  Future<ApprovalDecision> request(AgentApprovalRequest request) =>
      Future.delayed(delay, () => ApprovalDecision.approved);
}
