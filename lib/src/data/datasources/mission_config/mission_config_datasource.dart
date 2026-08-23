// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/mission_config/mission_config.dart';

abstract class MissionConfigDataSource with Loggable, FailureHandler {
  Future<MissionConfig> get(QueryParams<MissionConfig> params);
  Future<MissionConfig> update(UpdateParams<String, MissionConfigPatch> params);
}

// END GENERATED
