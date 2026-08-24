// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issues arrrrny/zuraffa_agent#25 and arrrrny/zuraffa_agent#26.
//
// Mock datasource for the RepetitionTracker value object. Mirrors the zfa-generated
// mock_datasource stub convention (see
// `lib/src/data/datasources/turn_record/turn_record_remote_datasource.dart`
// for the reference shape). Bodies throw UnimplementedError until a real
// store is wired by the consuming application.

import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/repetition_tracker/repetition_tracker.dart';
import 'repetition_tracker_datasource.dart';

class RepetitionTrackerMockDatasource
    with Loggable, FailureHandler
    implements RepetitionTrackerDatasource {
  RepetitionTrackerMockDatasource();

  @override
  Future<RepetitionTracker> current() async =>
      throw UnimplementedError('Implement RepetitionTrackerMockDatasource.current');

  @override
  Future<void> reset() async =>
      throw UnimplementedError('Implement RepetitionTrackerMockDatasource.reset');
}
