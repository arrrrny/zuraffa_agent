// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../entities/mission_config/mission_config.dart';

/// Service interface for EngineLoopService
abstract class EngineLoopService {
  Future<void> executeMission(MissionConfig params);

  void injectSteering(String params);

  Future<void> abortMission(NoParams params);
}

// END GENERATED
