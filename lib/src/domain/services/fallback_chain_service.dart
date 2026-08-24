// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#5 (R4 - providers & fallback).
//
// Service interface for the FallbackChain value object - same shape as
// SteeringQueueService (spec 033) and ToolResultService (spec 031):
// parameterless methods declare NoParams params so the implementing
// provider can @override them without ambiguity.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../entities/fallback_chain/fallback_chain.dart';

/// Service surface for the FallbackChain value object.
abstract class FallbackChainService with Loggable, FailureHandler {
  /// Returns the current FallbackChain snapshot for the active mission.
  Future<FallbackChain> current(NoParams params);

  /// Returns the count of FallbackChain records for the active mission.
  Future<int> count(NoParams params);
}
