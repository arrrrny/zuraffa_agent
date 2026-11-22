# Contract: Approval gate (pi#12-gated)

**Feature**: specs/205-zuraffa-governance-over-pi | **Date**: 2026-11-22

Durable approvals use pi signals, memoized deadlines, and host-provided
presentation/notification ports (FR-004). The gate is represented by a
wrapper-owned interface (`ApprovalGate`) and is only backed by pi#12 durable
primitives once pi#12 lands; before then it returns a typed
`durableUnavailable` outcome (FR-011, SC-011).

## Shape (logical)

```dart
/// Wrapper-owned interface. Backed by pi#12 durable primitives once landed;
/// before then, calls return a typed `durableUnavailable` outcome.
abstract class ApprovalGate {
  /// Requests approval for a tool invocation. The host's AgentApprovalPort
  /// presents the request and returns grant/deny. A timeout denies by default.
  Future<ApprovalOutcome> request(ApprovalRequest request);
}

class ApprovalRequest {
  final String toolName;
  final RiskTier tier;
  final Duration deadline;          // memoized; a timeout denies
  final Map<String, Object?> args;  // redacted before presentation
}

sealed class ApprovalOutcome {
  ApprovalGranted get granted;
  ApprovalDenied get denied;
  ApprovalExpired get expired;
  DurableUnavailable get durableUnavailable;   // pre-pi#12
}
```

## Behavior

1. The `beforeTool` hook calls `ApprovalGate.request` when the tool's tier
   is in `GovernancePolicy.requireApprovalForTiers` (FR-004).
2. The gate presents the request via the host's `AgentApprovalPort`
   (presentation + notification); the wrapper never presents UI and never
   reads `GetIt.instance` (FR-004, SC-005).
3. A grant allows execution; a deny yields a typed denial outcome and the
   tool never executes (SC-004).
4. A timeout past the memoized deadline yields a typed expiry outcome and
   the gate denies by default (SC-004).
5. A missing `AgentApprovalPort` yields a typed `missingApprovalPort`
   outcome — no global fallback (SC-005).
6. Before pi#12 lands, durable behavior is unavailable: the call returns
   `durableUnavailable` and the audit row records the unavailability
   (FR-011, SC-011).

## Audit

Every gate outcome — `approvalGranted`, `approvalDenied`,
`approvalExpired`, `missingApprovalPort`, `durableUnavailable` — is
recorded as an `AgentAuditRecord` via `AgentTelemetryPort` (FR-005).

## State transitions

`requested → granted | denied | expired`. Before pi#12 the gate is
interface-only; no durable state transition is claimed.