// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/golden_mission/golden_mission.dart';

abstract class GoldenMissionDataSource with Loggable, FailureHandler {
  Future<GoldenMission> get(QueryParams<GoldenMission> params);
  Future<GoldenMission> update(UpdateParams<String, GoldenMissionPatch> params);
}

// END GENERATED
