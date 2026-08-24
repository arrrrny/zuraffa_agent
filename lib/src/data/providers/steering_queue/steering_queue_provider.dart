// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#2 (R1 — engine core: steering & follow-up
// queues).
//
// Concrete provider stub for the SteeringQueue data layer. Mirrors the
// ToolResultProvider pattern from PR #49 and the AgentSessionProvider
// pattern from PR #50: bodies throw UnimplementedError so the file is
// analyzable without forcing real I/O. Parameterless methods (current,
// count) declare NoParams params so the @override clause matches the
// SteeringQueueService interface exactly.

import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/steering_queue/steering_queue.dart';
import '../../../domain/services/steering_queue_service.dart';

class SteeringQueueProvider
    with Loggable, FailureHandler
    implements SteeringQueueService {
  SteeringQueueProvider();

  @override
  Future<SteeringQueue> current(NoParams params) async =>
      throw UnimplementedError('Implement SteeringQueueProvider.current');

  @override
  Future<int> count(NoParams params) async =>
      throw UnimplementedError('Implement SteeringQueueProvider.count');
}
