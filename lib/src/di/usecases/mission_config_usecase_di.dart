// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/usecases/mission_config/update_mission_config_usecase.dart';
import '../../domain/usecases/mission_config/get_mission_config_usecase.dart';

void registerMissionConfigUseCase(GetIt getIt) {
  getIt.registerLazySingleton<UpdateMissionConfigUseCase>(() => UpdateMissionConfigUseCase(getIt()));
  getIt.registerLazySingleton<GetMissionConfigUseCase>(() => GetMissionConfigUseCase(getIt()));
}

// END GENERATED
