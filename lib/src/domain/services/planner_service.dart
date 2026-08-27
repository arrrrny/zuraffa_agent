// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#1 (epic — native agent engine) and
// specs/014-planner-todo-system (gap-analysis row 7: Planner/TODO system).
//
// Service interface for the Planner/TODO system — same shape as
// StopPolicyService (PR #48) and SteeringQueueService (PR #51).
// Parameterless methods declare `NoParams params` so the implementing
// provider can `@override` them without ambiguity. The service surface
// is value-object-appropriate: callers read the current plan snapshot
// and the configured plan mode.

import 'package:zuraffa/zuraffa.dart';

import '../entities/planner/plan_mode.dart';
import '../entities/planner/plan_state.dart';

/// Service surface for the Planner/TODO system.
abstract class PlannerService with Loggable, FailureHandler {
  /// Returns the current [PlanState] for the active mission.
  Future<PlanState> current(NoParams params);

  /// Returns the configured [PlanMode] for the active mission.
  Future<PlanMode> mode(NoParams params);
}
