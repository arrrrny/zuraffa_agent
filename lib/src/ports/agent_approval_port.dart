/// Host-injection port for approval presentation / human notify (FR-006).
///
/// [AgentApprovalRequest] / [ApprovalDecision] are this port's own minimal
/// shape until pi#12's durable signals land, at which point #205 bridges the
/// two. The wrapper does not claim a durable gate (FR-010). Tests use
/// [InMemoryAgentApprovalPort].
library;

/// A request for the host to present an approval to a human.
class AgentApprovalRequest {
  final String id;
  final String prompt;
  final Map<String, dynamic> details;

  const AgentApprovalRequest({
    required this.id,
    required this.prompt,
    this.details = const {},
  });
}

/// The host's decision on an [AgentApprovalRequest].
enum ApprovalDecision { approved, denied }

/// Presents approval requests to the host and returns its decision.
abstract class AgentApprovalPort {
  Future<ApprovalDecision> request(AgentApprovalRequest request);
}

/// Pure-Dart in-memory [AgentApprovalPort] that returns a scripted decision and
/// records every request.
class InMemoryAgentApprovalPort implements AgentApprovalPort {
  final List<AgentApprovalRequest> requests = [];
  ApprovalDecision decision;

  InMemoryAgentApprovalPort({this.decision = ApprovalDecision.approved});

  @override
  Future<ApprovalDecision> request(AgentApprovalRequest request) async {
    requests.add(request);
    return decision;
  }
}
