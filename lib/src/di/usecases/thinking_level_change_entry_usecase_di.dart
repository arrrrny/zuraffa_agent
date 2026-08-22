// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/usecases/thinking_level_change_entry/update_thinking_level_change_entry_usecase.dart';
import '../../domain/usecases/thinking_level_change_entry/get_thinking_level_change_entry_usecase.dart';

void registerThinkingLevelChangeEntryUseCase(GetIt getIt) {
  getIt.registerLazySingleton<UpdateThinkingLevelChangeEntryUseCase>(() => UpdateThinkingLevelChangeEntryUseCase(getIt()));
  getIt.registerLazySingleton<GetThinkingLevelChangeEntryUseCase>(() => GetThinkingLevelChangeEntryUseCase(getIt()));
}

// END GENERATED
