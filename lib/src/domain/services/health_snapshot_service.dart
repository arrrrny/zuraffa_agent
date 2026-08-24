// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#5 (R4 - providers & fallback).
//
// Service interface for the HealthSnapshot value object - same shape as
// SteeringQueueService (spec 033) and ToolResultService (spec 031):
// parameterless methods declare NoParams params so the implementing
// provider can @override them without ambiguity.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../entities/health_snapshot/health_snapshot.dart';

/// Service surface for the HealthSnapshot value object.
abstract class HealthSnapshotService with Loggable, FailureHandler {
  /// Returns the current HealthSnapshot snapshot for the active mission.
  Future<HealthSnapshot> current(NoParams params);

  /// Returns the count of HealthSnapshot records for the active mission.
  Future<int> count(NoParams params);
}
