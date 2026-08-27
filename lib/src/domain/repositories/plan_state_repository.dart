// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrrny/zuraffa_agent#1 (epic — native agent engine) and
// specs/014-planner-todo-system (gap-analysis row 7: Planner/TODO system).
//
// zfa v6.0.0's `zfa make <Entity> repository usecase di mock provider
// service datasource` crashes for every entity (issue #14) and the
// clean-architecture layers never emit. This file is the canonical
// hand-curated repository interface for the PlanState value object,
// mirroring the StopPolicyRepository pattern from PR #48.
//
// PlanState is a value object (one snapshot per mission), so the
// repository surface is value-object-appropriate: read current +
// update + reset — no CRUD, no identity mutation.

import 'package:zuraffa/zuraffa.dart';

import '../entities/planner/plan_state.dart';

abstract class PlanStateRepository with Loggable, FailureHandler {
  /// Returns the current [PlanState] for the mission with [id].
  /// Misses surface as failures through the FailureHandler contract.
  Future<PlanState> getCurrent(String id);

  /// Persists [state] as the latest snapshot (full replace; PlanState
  /// is immutable). Returns the persisted snapshot.
  Future<PlanState> update(PlanState state);

  /// Resets the mission's plan to an empty state.
  Future<void> reset(String id);
}
