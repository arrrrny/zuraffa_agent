// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#8 (UI/tree+json payloads).
//
// Service interface for the UiTreePayload value object — same shape as
// ToolResultService (PR #49 / issue #31), AgentSessionService (PR #50 /
// issue #1), AgentToolService (PR #52 / issue #4), CircuitBreakerService
// (PR #53 / issue #5), SubAgentSpecService (PR #54 / issue #6), and
// PassAtKService (PR #55 / issue #7). Parameterless methods declare
// `NoParams params` so the implementing provider can `@override` them
// without ambiguity. The service surface is value-object-appropriate:
// no CRUD, no identity mutation — callers read the most-recently-emitted
// payload and the count of payloads in the active mission.

import 'package:zuraffa/zuraffa.dart';

import '../entities/ui_tree_payload/ui_tree_payload.dart';

/// Service surface for the UiTreePayload value object.
abstract class UiTreePayloadService with Loggable, FailureHandler {
  /// Returns the most-recently-emitted ui/tree+json payload in the
  /// active mission.
  Future<UiTreePayload> current(NoParams params);

  /// Returns the count of ui/tree+json payloads emitted in the active
  /// mission.
  Future<int> count(NoParams params);
}
