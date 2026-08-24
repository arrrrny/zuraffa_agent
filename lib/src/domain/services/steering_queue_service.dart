// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#2 (R1 — engine core: steering & follow-up
// queues).
//
// Service interface for the SteeringQueue value object — same shape as
// ToolResultService (PR #49 / issue #31) and AgentSessionService (PR #50 /
// issue #1). Parameterless methods declare `NoParams params` so the
// implementing provider can `@override` them without ambiguity. The
// service surface is value-object-appropriate: no CRUD, no identity
// mutation — callers read the current queue snapshot and the count of
// pending messages.

import 'package:zuraffa/zuraffa.dart';

import '../entities/steering_queue/steering_queue.dart';

/// Service surface for the SteeringQueue value object.
abstract class SteeringQueueService with Loggable, FailureHandler {
  /// Returns the current (head) queue snapshot for the active mission.
  Future<SteeringQueue> current(NoParams params);

  /// Returns the count of pending messages in the current queue
  /// snapshot for the active mission.
  Future<int> count(NoParams params);
}
