/// Risk classification for tool governance (issue #205, data-model.md).
///
/// A plain value enum consumed by [GovernancePolicy] and the pi `beforeTool`
/// hooks for allow/deny/approval decisions. It carries no generated model
/// boilerplate (copyWith/==/toJson), so it is declared directly rather than
/// emitted by Zorphy; Zorphy consumes it as a field type.
library;

/// The gate key for allow/deny/approval decisions.
enum RiskTier {
  /// Permitted without an approval gate.
  low,

  /// Permitted; a host may gate it.
  medium,

  /// Gated through [AgentApprovalPort] when configured (FR-004).
  high,

  /// Always gated; the strictest tier.
  critical,
}
