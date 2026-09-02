// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#8 (Wave U — Generative UI).
//
// MissionBudget value object + enforcer — issue #8 §3 ("Budget
// integration"): tree size/depth caps join mission budgets via the
// plugin `MissionBudgetHook`. The engine stays UI-framework-agnostic
// (issue #8 §6): this file carries the value object and the pure
// enforcer function the plugin-side hook calls. The hook wiring itself
// lives in the plugin (per issue #8: "rendering belongs to the
// plugin/app").
//
// Plain Dart, no @Zorphy codegen, compiles without build_runner — same
// pattern as UiTreePayload, UiSpec, and the other hand-curated value
// objects.

import '../ui_tree_payload/ui_tree_payload.dart';

/// Mission budget caps — issue #8 §3 + §8.3.
///
/// A mission budget carries the resource caps the engine enforces during
/// a run. UI tree caps ([maxUiTreeDepth], [maxUiTreeNodeCount]) join the
/// budget so a UI-spamming agent trips it like any other resource: a
/// tree exceeding either cap raises [UiBudgetExceededError] when the
/// enforcer runs.
///
/// Both UI caps are nullable so a mission can pin only one dimension
/// (e.g. depth but not node count). A `null` cap means "no cap on this
/// dimension".
class MissionBudget {
  /// Maximum tree depth (root inclusive; a leaf has depth 1).
  /// When null, depth is uncapped.
  final int? maxUiTreeDepth;

  /// Maximum total node count (root inclusive).
  /// When null, node count is uncapped.
  final int? maxUiTreeNodeCount;

  const MissionBudget({this.maxUiTreeDepth, this.maxUiTreeNodeCount});

  /// Returns `true` when at least one UI cap is set.
  bool get hasAnyUiCap => maxUiTreeDepth != null || maxUiTreeNodeCount != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MissionBudget &&
          runtimeType == other.runtimeType &&
          maxUiTreeDepth == other.maxUiTreeDepth &&
          maxUiTreeNodeCount == other.maxUiTreeNodeCount);

  @override
  int get hashCode => Object.hash(maxUiTreeDepth, maxUiTreeNodeCount);

  @override
  String toString() =>
      'MissionBudget(maxUiTreeDepth: $maxUiTreeDepth, '
      'maxUiTreeNodeCount: $maxUiTreeNodeCount)';
}

/// Typed error raised by [MissionBudgetEnforcer.checkUiTree] when a
/// [UiTreePayload] exceeds a [MissionBudget] cap (issue #8 §3).
class UiBudgetExceededError implements Exception {
  /// Which cap was exceeded.
  final String field;

  /// The value the payload carried.
  final int actual;

  /// The cap the budget pinned.
  final int cap;

  UiBudgetExceededError({
    required this.field,
    required this.actual,
    required this.cap,
  });

  @override
  String toString() => 'UiBudgetExceededError: $field $actual exceeds cap $cap';
}

/// Pure enforcer for the UI tree dimension of a [MissionBudget]
/// (issue #8 §3).
///
/// The plugin-side `MissionBudgetHook` calls [checkUiTree] at the
/// tool-result boundary: when a tool emits a `ui/tree+json` payload,
/// the hook constructs the [UiTreePayload] (from
/// [UiTreePayload.fromJson]) and hands it here with the mission's
/// budget. [checkUiTree] throws [UiBudgetExceededError] on the first
/// exceeded cap; it returns silently when the payload is within budget
/// or when the budget has no UI caps.
///
/// The check is O(1): [UiTreePayload.depth] and [UiTreePayload.nodeCount]
/// are precomputed at construction (spec 038 FR-005), so the enforcer
/// is a pair of integer comparisons — no tree walk.
class MissionBudgetEnforcer {
  const MissionBudgetEnforcer();

  /// Throws [UiBudgetExceededError] when [payload] exceeds any UI cap
  /// in [budget]. Returns silently otherwise.
  ///
  /// When [budget] has no UI caps ([MissionBudget.hasAnyUiCap] is false),
  /// this is a no-op — the mission has not pinned UI budgets, so the
  /// enforcer has nothing to enforce.
  void checkUiTree(UiTreePayload payload, MissionBudget budget) {
    final depthCap = budget.maxUiTreeDepth;
    if (depthCap != null && payload.depth > depthCap) {
      throw UiBudgetExceededError(
        field: 'depth',
        actual: payload.depth,
        cap: depthCap,
      );
    }
    final nodeCap = budget.maxUiTreeNodeCount;
    if (nodeCap != null && payload.nodeCount > nodeCap) {
      throw UiBudgetExceededError(
        field: 'nodeCount',
        actual: payload.nodeCount,
        cap: nodeCap,
      );
    }
  }
}
