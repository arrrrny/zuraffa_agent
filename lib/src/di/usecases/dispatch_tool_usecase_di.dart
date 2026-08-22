// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/usecases/dispatch_tool/get_dispatch_tool_usecase.dart';
import '../../domain/usecases/dispatch_tool/update_dispatch_tool_usecase.dart';

void registerDispatchToolUseCase(GetIt getIt) {
  getIt.registerLazySingleton<GetDispatchToolUseCase>(() => GetDispatchToolUseCase(getIt()));
  getIt.registerLazySingleton<UpdateDispatchToolUseCase>(() => UpdateDispatchToolUseCase(getIt()));
}

// END GENERATED
