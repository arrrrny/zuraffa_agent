// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/mission_config/mission_config.dart';
import '../../../domain/services/engine_loop_service.dart';

class EngineLoopProvider
    with Loggable, FailureHandler
    implements EngineLoopService {
  @override
  Future<void> executeMission(MissionConfig params) async {
    final error = UnimplementedError('executeMission not implemented');
    final stack = StackTrace.current;
    logAndHandleError(error, stack);
    throw error;
  }

  @override
  void injectSteering(String params) {
    final error = UnimplementedError('injectSteering not implemented');
    final stack = StackTrace.current;
    logAndHandleError(error, stack);
    throw error;
  }

  @override
  Future<void> abortMission(NoParams params) async {
    final error = UnimplementedError('abortMission not implemented');
    final stack = StackTrace.current;
    logAndHandleError(error, stack);
    throw error;
  }
}

// END GENERATED