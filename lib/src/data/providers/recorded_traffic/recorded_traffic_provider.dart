// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#7 (R6 - eval harness).
//
// Concrete provider for the RecordedTraffic data layer. Returns the active
// recorded-LLM/tool-traffic snapshot. Replaces the previous
// UnimplementedError stub (spec 037).

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/recorded_traffic/recorded_traffic.dart';
import '../../../domain/services/recorded_traffic_service.dart';

class RecordedTrafficProvider
    with Loggable, FailureHandler
    implements RecordedTrafficService {
  final RecordedTraffic _active;

  RecordedTrafficProvider([RecordedTraffic? active])
      : _active = active ??
            const RecordedTraffic(
              id: 'default',
              missionId: 'mission-1',
              llmCallCount: 0,
              toolCallCount: 0,
              recordedAt: 0,
            );

  @override
  Future<RecordedTraffic> current(NoParams params) async => _active;

  @override
  Future<int> count(NoParams params) async => 1;
}
