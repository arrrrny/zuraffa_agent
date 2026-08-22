// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/usecases/compaction_entry/get_compaction_entry_usecase.dart';
import '../../domain/usecases/compaction_entry/update_compaction_entry_usecase.dart';

void registerCompactionEntryUseCase(GetIt getIt) {
  getIt.registerLazySingleton<GetCompactionEntryUseCase>(() => GetCompactionEntryUseCase(getIt()));
  getIt.registerLazySingleton<UpdateCompactionEntryUseCase>(() => UpdateCompactionEntryUseCase(getIt()));
}

// END GENERATED
