// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/usecases/model_change_entry/get_model_change_entry_usecase.dart';
import '../../domain/usecases/model_change_entry/update_model_change_entry_usecase.dart';

void registerModelChangeEntryUseCase(GetIt getIt) {
  getIt.registerLazySingleton<GetModelChangeEntryUseCase>(() => GetModelChangeEntryUseCase(getIt()));
  getIt.registerLazySingleton<UpdateModelChangeEntryUseCase>(() => UpdateModelChangeEntryUseCase(getIt()));
}

// END GENERATED
