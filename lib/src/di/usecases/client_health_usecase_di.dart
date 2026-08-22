// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/usecases/engine/mark_failure_usecase.dart';
import '../../domain/usecases/engine/is_healthy_usecase.dart';

void registerClientHealthUseCase(GetIt getIt) {
  getIt.registerLazySingleton<MarkFailureUseCase>(() => MarkFailureUseCase(getIt()));
  getIt.registerLazySingleton<IsHealthyUseCase>(() => IsHealthyUseCase(getIt()));
}

// END GENERATED