// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/usecases/engine/select_provider_usecase.dart';
import '../../domain/usecases/engine/record_failure_usecase.dart';

void registerFallbackChainUseCase(GetIt getIt) {
  getIt.registerLazySingleton<SelectProviderUseCase>(() => SelectProviderUseCase(getIt()));
  getIt.registerLazySingleton<RecordFailureUseCase>(() => RecordFailureUseCase(getIt()));
}

// END GENERATED