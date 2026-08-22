// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/usecases/turn_context/update_turn_context_usecase.dart';
import '../../domain/usecases/turn_context/get_turn_context_usecase.dart';

void registerTurnContextUseCase(GetIt getIt) {
  getIt.registerLazySingleton<UpdateTurnContextUseCase>(() => UpdateTurnContextUseCase(getIt()));
  getIt.registerLazySingleton<GetTurnContextUseCase>(() => GetTurnContextUseCase(getIt()));
}

// END GENERATED
