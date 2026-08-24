// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#7 (R6 - eval harness).
//
// Service interface for the RecordedTraffic value object - same shape as
// SteeringQueueService (spec 033) and ToolResultService (spec 031):
// parameterless methods declare NoParams params so the implementing
// provider can @override them without ambiguity.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../entities/recorded_traffic/recorded_traffic.dart';

/// Service surface for the RecordedTraffic value object.
abstract class RecordedTrafficService with Loggable, FailureHandler {
  /// Returns the current RecordedTraffic snapshot for the active mission.
  Future<RecordedTraffic> current(NoParams params);

  /// Returns the count of RecordedTraffic records for the active mission.
  Future<int> count(NoParams params);
}
