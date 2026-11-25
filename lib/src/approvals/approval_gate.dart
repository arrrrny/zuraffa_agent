/// The wrapper-owned approval gate (FR-004, SC-004, SC-005, SC-011,
/// contracts/approval-gate.md).
///
/// Durable approvals use pi signals, memoized deadlines, and the host's
/// [AgentApprovalPort] for presentation/notification. The wrapper never
/// presents UI and never reads a global service locator. The durable surface
/// (pi#12) is not yet available, so a durable request returns
/// [DurableUnavailable]; before then the gate still grants/denies/expires
/// through the host port for the non-durable path.
library;

import 'dart:async';

import '../governance/entities/risk_tier.dart';
import '../ports/agent_approval_port.dart';

/// A request to approve a tool invocation.
class ApprovalRequest {
  final String toolName;
  final RiskTier tier;

  /// Memoized deadline; a timeout denies by default.
  final Duration deadline;
  final Map<String, Object?> args;

  const ApprovalRequest({
    required this.toolName,
    required this.tier,
    required this.deadline,
    this.args = const {},
  });
}

/// The outcome of an approval request.
sealed class ApprovalOutcome {
  const ApprovalOutcome();
}

/// The host granted the request.
class ApprovalGranted extends ApprovalOutcome {
  const ApprovalGranted();
}

/// The host denied the request; the tool never executes.
class ApprovalDenied extends ApprovalOutcome {
  const ApprovalDenied();
}

/// The memoized deadline elapsed; the gate denies by default.
class ApprovalExpired extends ApprovalOutcome {
  const ApprovalExpired();
}

/// No [AgentApprovalPort] was injected (no global fallback, SC-005).
class MissingApprovalPort extends ApprovalOutcome {
  const MissingApprovalPort();
}

/// The durable (pi#12) surface is not yet available (SC-011).
class DurableUnavailable extends ApprovalOutcome {
  const DurableUnavailable();
}

/// Presents approval requests through the host port and returns a typed
/// outcome. Construct with [durable] true to exercise the pi#12-gated surface,
/// which returns [DurableUnavailable] until pi#12 lands.
class ApprovalGate {
  final AgentApprovalPort? _port;
  final bool durable;

  ApprovalGate({required AgentApprovalPort? port, this.durable = false})
    : _port = port;

  /// Requests approval for [request].
  Future<ApprovalOutcome> request(ApprovalRequest request) async {
    if (durable) return const DurableUnavailable();
    final port = _port;
    if (port == null) return const MissingApprovalPort();

    final AgentApprovalRequest agentRequest = AgentApprovalRequest(
      id: request.toolName,
      prompt: 'Approve ${request.tier.name}-tier tool "${request.toolName}"?',
      details: Map<String, dynamic>.from(request.args),
    );

    final ApprovalDecision decision;
    try {
      decision = await port.request(agentRequest).timeout(request.deadline);
    } on TimeoutException {
      // A timeout past the memoized deadline denies by default (SC-004).
      return const ApprovalExpired();
    }

    switch (decision) {
      case ApprovalDecision.approved:
        return const ApprovalGranted();
      case ApprovalDecision.denied:
        return const ApprovalDenied();
    }
  }
}
