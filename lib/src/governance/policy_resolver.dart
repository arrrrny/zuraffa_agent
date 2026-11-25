/// Deterministic governance policy merge (issue #205 edge cases,
/// contracts/governance-hooks.md).
///
/// When more than one [GovernancePolicy] is installed the wrapper merges them
/// deterministically instead of silently picking one: deny wins over allow,
/// the stricter [RiskTier] wins, redaction rules union by name (first wins),
/// approval tiers union, and the smallest oversized-result threshold wins.
/// [isDenied] encodes default-deny (FR-002): a tool in neither the allow nor
/// the deny list is denied.
library;

import '../governance/entities/governance_policy.dart';
import '../governance/entities/redaction_rule.dart';
import '../governance/entities/risk_tier.dart';

/// Merges installed [GovernancePolicy] values and answers governance queries.
class PolicyResolver {
  const PolicyResolver();

  /// The default oversized-result threshold in bytes (256 KiB), used when no
  /// policy sets one (contracts/artifact-router.md).
  static const int defaultOversizedThreshold = 256 * 1024;

  /// Deterministically merges [policies] in order into one effective policy.
  GovernancePolicy merge(List<GovernancePolicy> policies) {
    final allow = <String>{};
    final deny = <String>{};
    final tiers = <String, RiskTier>{};
    final rules = <String, RedactionRule>{};
    final approval = <RiskTier>{};
    int? threshold;

    for (final policy in policies) {
      allow.addAll(policy.toolAllowList);
      deny.addAll(policy.toolDenyList);
      for (final entry in policy.riskTiers.entries) {
        // Stricter tier wins; on a tie the first seen is kept.
        final existing = tiers[entry.key];
        if (existing == null || _stricter(entry.value, existing)) {
          tiers[entry.key] = entry.value;
        }
      }
      for (final rule in policy.redactionRules) {
        // First rule wins for a duplicated name (deterministic).
        rules.putIfAbsent(rule.name, () => rule);
      }
      approval.addAll(policy.requireApprovalForTiers);
      final t = policy.oversizedResultThreshold;
      if (t != null && (threshold == null || t < threshold)) threshold = t;
    }

    // Deny wins over allow: a denied tool is removed from the allow set so the
    // two are disjoint (data-model validation: allow ∩ deny = ∅).
    allow.removeAll(deny);

    return GovernancePolicy(
      id: 'merged',
      toolAllowList: allow.toList()..sort(),
      toolDenyList: deny.toList()..sort(),
      riskTiers: tiers,
      redactionRules: rules.values.toList(),
      requireApprovalForTiers: approval.toList(),
      oversizedResultThreshold: threshold,
    );
  }

  /// Default-deny (FR-002): a tool is denied when it is on the deny list, or
  /// when it is on neither the allow nor the deny list.
  bool isDenied(GovernancePolicy policy, String toolName) {
    if (policy.toolDenyList.contains(toolName)) return true;
    return !policy.toolAllowList.contains(toolName);
  }

  /// The effective risk tier for [toolName], defaulting to [RiskTier.critical]
  /// for an unregistered tool (contracts/governance-hooks.md step 1).
  RiskTier tierOf(GovernancePolicy policy, String toolName) =>
      policy.riskTiers[toolName] ?? RiskTier.critical;

  /// Whether [toolName] requires an approval gate.
  bool requiresApproval(GovernancePolicy policy, String toolName) =>
      policy.requireApprovalForTiers.contains(tierOf(policy, toolName));

  /// The effective oversized-result threshold in bytes.
  int oversizedThreshold(GovernancePolicy policy) =>
      policy.oversizedResultThreshold ?? defaultOversizedThreshold;

  static bool _stricter(RiskTier a, RiskTier b) => a.index > b.index;
}
