// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#3 (R1 - state & sessions).
//
// Service interface for the SessionTreeEntry value object - same shape as
// SteeringQueueService (spec 033) and ToolResultService (spec 031):
// parameterless methods declare NoParams params so the implementing
// provider can @override them without ambiguity.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../entities/session_tree_entry/session_tree_entry.dart';

/// Service surface for the SessionTreeEntry value object.
abstract class SessionTreeEntryService with Loggable, FailureHandler {
  /// Returns the current SessionTreeEntry snapshot for the active mission.
  Future<SessionTreeEntry> current(NoParams params);

  /// Returns the count of SessionTreeEntry records for the active mission.
  Future<int> count(NoParams params);
}
