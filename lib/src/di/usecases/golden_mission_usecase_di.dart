// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/usecases/engine/record_golden_mission_usecase.dart';
import '../../domain/usecases/engine/replay_golden_mission_usecase.dart';

void registerGoldenMissionUseCase(GetIt getIt) {
  getIt.registerLazySingleton<RecordGoldenMissionUseCase>(() => RecordGoldenMissionUseCase(getIt()));
  getIt.registerLazySingleton<ReplayGoldenMissionUseCase>(() => ReplayGoldenMissionUseCase(getIt()));
}

// END GENERATED