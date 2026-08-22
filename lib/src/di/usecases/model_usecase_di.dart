// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/usecases/model/update_model_usecase.dart';
import '../../domain/usecases/model/get_model_usecase.dart';

void registerModelUseCase(GetIt getIt) {
  getIt.registerLazySingleton<UpdateModelUseCase>(() => UpdateModelUseCase(getIt()));
  getIt.registerLazySingleton<GetModelUseCase>(() => GetModelUseCase(getIt()));
}

// END GENERATED
