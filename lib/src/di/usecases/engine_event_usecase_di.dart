// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/usecases/engine_event/update_engine_event_usecase.dart';
import '../../domain/usecases/engine_event/get_engine_event_usecase.dart';

void registerEngineEventUseCase(GetIt getIt) {
  getIt.registerLazySingleton<UpdateEngineEventUseCase>(() => UpdateEngineEventUseCase(getIt()));
  getIt.registerLazySingleton<GetEngineEventUseCase>(() => GetEngineEventUseCase(getIt()));
}

// END GENERATED
