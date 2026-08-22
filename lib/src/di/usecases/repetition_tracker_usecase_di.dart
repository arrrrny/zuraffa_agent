// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/usecases/repetition_tracker/get_repetition_tracker_usecase.dart';
import '../../domain/usecases/repetition_tracker/update_repetition_tracker_usecase.dart';

void registerRepetitionTrackerUseCase(GetIt getIt) {
  getIt.registerLazySingleton<GetRepetitionTrackerUseCase>(() => GetRepetitionTrackerUseCase(getIt()));
  getIt.registerLazySingleton<UpdateRepetitionTrackerUseCase>(() => UpdateRepetitionTrackerUseCase(getIt()));
}

// END GENERATED
