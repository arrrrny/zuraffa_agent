// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#14.
//
// Service interface for the StopPolicy value object — the parameterless
// service surface mirrors ArtifactService (PR #32 / issue #11). Both methods
// declare `NoParams params` so the implementing provider can `@override` them
// without ambiguity.

import 'package:zuraffa/zuraffa.dart';

import '../entities/stop_policy/stop_policy.dart';

abstract class StopPolicyService with Loggable, FailureHandler {
  /// Returns the currently active [StopPolicy].
  Future<StopPolicy> current(NoParams params);

  /// Returns the default [StopPolicy] (maxTurns=100, wallClockTimeout=0,
  /// repetitionThreshold=5, enabled=true) used as the reset target.
  StopPolicy defaultPolicy(NoParams params);
}
