// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#7 (R6 - eval harness).
//
// Service interface for the DartIoFreeGate value object - same shape as
// SteeringQueueService (spec 033) and ToolResultService (spec 031):
// parameterless methods declare NoParams params so the implementing
// provider can @override them without ambiguity.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../entities/dart_io_free_gate/dart_io_free_gate.dart';

/// Service surface for the DartIoFreeGate value object.
abstract class DartIoFreeGateService with Loggable, FailureHandler {
  /// Returns the current DartIoFreeGate snapshot for the active mission.
  Future<DartIoFreeGate> current(NoParams params);

  /// Returns the count of DartIoFreeGate records for the active mission.
  Future<int> count(NoParams params);
}
