// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#2 (R1 — engine core: steering & follow-up
// queues).
//
// Concrete provider for the SteeringQueue data layer. Returns the active
// queue snapshot for the running mission. Backed by an in-memory repository
// of queue snapshots; current() returns the active (most-recent) snapshot and
// count() returns the number of tracked snapshots. Replaces the previous stub
// (spec 033).

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/steering_queue/steering_queue.dart';
import '../../../domain/services/steering_queue_service.dart';

class SteeringQueueProvider
    with Loggable, FailureHandler
    implements SteeringQueueService {
  final List<SteeringQueue> _queues;

  SteeringQueueProvider([SteeringQueue? active])
      : _queues = [
          active ??
              const SteeringQueue(
                id: 'queue-default',
                pending: [],
                processedCount: 0,
              ),
        ];

  @override
  Future<SteeringQueue> current(NoParams params) async => _queues.last;

  @override
  Future<int> count(NoParams params) async => _queues.length;
}
