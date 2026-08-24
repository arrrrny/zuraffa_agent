// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#3 (R1 - state & sessions).
//
// Service interface for the SessionBranch value object - same shape as
// SteeringQueueService (spec 033) and ToolResultService (spec 031):
// parameterless methods declare NoParams params so the implementing
// provider can @override them without ambiguity.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../entities/session_branch/session_branch.dart';

/// Service surface for the SessionBranch value object.
abstract class SessionBranchService with Loggable, FailureHandler {
  /// Returns the current SessionBranch snapshot for the active mission.
  Future<SessionBranch> current(NoParams params);

  /// Returns the count of SessionBranch records for the active mission.
  Future<int> count(NoParams params);
}
