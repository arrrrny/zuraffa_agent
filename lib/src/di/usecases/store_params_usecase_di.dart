// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/usecases/store_params/get_store_params_usecase.dart';
import '../../domain/usecases/store_params/update_store_params_usecase.dart';

void registerStoreParamsUseCase(GetIt getIt) {
  getIt.registerLazySingleton<GetStoreParamsUseCase>(() => GetStoreParamsUseCase(getIt()));
  getIt.registerLazySingleton<UpdateStoreParamsUseCase>(() => UpdateStoreParamsUseCase(getIt()));
}

// END GENERATED
