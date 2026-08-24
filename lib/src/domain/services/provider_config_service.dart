// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#5 (R4 - providers & fallback).
//
// Service interface for the ProviderConfig value object - same shape as
// SteeringQueueService (spec 033) and ToolResultService (spec 031):
// parameterless methods declare NoParams params so the implementing
// provider can @override them without ambiguity.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../entities/provider_config/provider_config.dart';

/// Service surface for the ProviderConfig value object.
abstract class ProviderConfigService with Loggable, FailureHandler {
  /// Returns the current ProviderConfig snapshot for the active mission.
  Future<ProviderConfig> current(NoParams params);

  /// Returns the count of ProviderConfig records for the active mission.
  Future<int> count(NoParams params);
}
