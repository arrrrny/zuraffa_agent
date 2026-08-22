// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/usecases/tool_result/get_tool_result_usecase.dart';
import '../../domain/usecases/tool_result/update_tool_result_usecase.dart';

void registerToolResultUseCase(GetIt getIt) {
  getIt.registerLazySingleton<GetToolResultUseCase>(() => GetToolResultUseCase(getIt()));
  getIt.registerLazySingleton<UpdateToolResultUseCase>(() => UpdateToolResultUseCase(getIt()));
}

// END GENERATED
