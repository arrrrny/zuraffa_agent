// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#1 (epic — native agent engine) and
// specs/014-planner-todo-system (gap-analysis row 7: Planner/TODO system).
//
// Concrete provider stub for the Planner/TODO data layer. Mirrors the
// StopPolicyProvider pattern from PR #48 and the SteeringQueueProvider
// pattern from PR #51: bodies throw UnimplementedError so the file is
// analyzable without forcing real I/O. Parameterless methods (current,
// mode) declare NoParams params so the @override clause matches the
// PlannerService interface exactly.

import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/planner/plan_mode.dart';
import '../../../domain/entities/planner/plan_state.dart';
import '../../../domain/services/planner_service.dart';

class PlannerProvider
    with Loggable, FailureHandler
    implements PlannerService {
  PlannerProvider();

  @override
  Future<PlanState> current(NoParams params) async =>
      throw UnimplementedError('Implement PlannerProvider.current');

  @override
  Future<PlanMode> mode(NoParams params) async =>
      throw UnimplementedError('Implement PlannerProvider.mode');
}
