// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/usecases/custom_entry/update_custom_entry_usecase.dart';
import '../../domain/usecases/custom_entry/get_custom_entry_usecase.dart';

void registerCustomEntryUseCase(GetIt getIt) {
  getIt.registerLazySingleton<UpdateCustomEntryUseCase>(() => UpdateCustomEntryUseCase(getIt()));
  getIt.registerLazySingleton<GetCustomEntryUseCase>(() => GetCustomEntryUseCase(getIt()));
}

// END GENERATED
