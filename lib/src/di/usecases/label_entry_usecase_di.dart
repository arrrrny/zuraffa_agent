// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/usecases/label_entry/update_label_entry_usecase.dart';
import '../../domain/usecases/label_entry/get_label_entry_usecase.dart';

void registerLabelEntryUseCase(GetIt getIt) {
  getIt.registerLazySingleton<UpdateLabelEntryUseCase>(() => UpdateLabelEntryUseCase(getIt()));
  getIt.registerLazySingleton<GetLabelEntryUseCase>(() => GetLabelEntryUseCase(getIt()));
}

// END GENERATED
