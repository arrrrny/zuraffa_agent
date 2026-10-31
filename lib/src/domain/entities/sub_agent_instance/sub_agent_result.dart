// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#6 (R5 - sub-agents & declarative).
//
// SubAgentResult (typed outcome) value object - spec-exact from epic #1 §R5
// (issue #6). Pattern mirrors SubAgentInstance / SteeringMessage: plain Dart,
// value equality across all fields, no @Zorphy codegen.

/// Typed category of a failed sub-agent run.
enum SubAgentFailureKind {
  /// The timeout value.
  timeout,

  /// The tool error value.
  toolError,

  /// The provider error value.
  providerError,

  /// The cancelled value.
  cancelled,

  /// The unknown value.
  unknown,
}

/// SubAgentResult — the typed outcome a sub-agent returns to its parent.
///
/// Success carries a human-readable [summary]; failure carries a typed
/// [failureKind] and a [failureReason]. The parent continues on either outcome
/// (epic #5 §R5, issue #6 US1/US5).
class SubAgentResult {
  /// The instance identifier.
  final String instanceId;

  /// Whether ok.
  final bool ok;

  /// The summary.
  final String summary;

  /// The failure kind.
  final SubAgentFailureKind? failureKind;

  /// The failure reason.
  final String? failureReason;

  /// Creates a sub agent result (success variant).
  const SubAgentResult.success({
    required this.instanceId,
    required this.summary,
  }) : ok = true,
       failureKind = null,
       failureReason = null;

  /// Creates a sub agent result (failure variant).
  const SubAgentResult.failure({
    required this.instanceId,
    required this.failureKind,
    required this.failureReason,
  }) : ok = false,
       summary = '';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubAgentResult &&
          runtimeType == other.runtimeType &&
          instanceId == other.instanceId &&
          ok == other.ok &&
          summary == other.summary &&
          failureKind == other.failureKind &&
          failureReason == other.failureReason);

  @override
  int get hashCode =>
      Object.hash(instanceId, ok, summary, failureKind, failureReason);

  @override
  String toString() =>
      'SubAgentResult(instanceId: $instanceId, ok: $ok'
      '${ok ? ', summary: "$summary"' : ', failureKind: $failureKind'})';
}
