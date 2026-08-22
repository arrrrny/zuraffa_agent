// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/golden_mission/golden_mission.dart';
import '../../../domain/services/golden_mission_service.dart';

class GoldenMissionProvider
    with Loggable, FailureHandler
    implements GoldenMissionService {
  @override
  void record(GoldenMission params) {
    final error = UnimplementedError('record not implemented');
    final stack = StackTrace.current;
    logAndHandleError(error, stack);
    throw error;
  }

  @override
  void replay(GoldenMission params) {
    final error = UnimplementedError('replay not implemented');
    final stack = StackTrace.current;
    logAndHandleError(error, stack);
    throw error;
  }
}

// END GENERATED
