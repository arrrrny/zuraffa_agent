// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#7 (R6 - eval harness).
//
// Concrete provider stub for the RecordedTraffic data layer. Mirrors the
// SteeringQueueProvider pattern (spec 033) and ToolResultProvider
// (spec 031): bodies throw UnimplementedError so the file is analyzable
// without forcing real I/O.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/recorded_traffic/recorded_traffic.dart';
import '../../../domain/services/recorded_traffic_service.dart';

class RecordedTrafficProvider
    with Loggable, FailureHandler
    implements RecordedTrafficService {
  RecordedTrafficProvider();

  @override
  Future<RecordedTraffic> current(NoParams params) async =>
      throw UnimplementedError('Implement RecordedTrafficProvider.current');

  @override
  Future<int> count(NoParams params) async =>
      throw UnimplementedError('Implement RecordedTrafficProvider.count');
}
