// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/usecases/tool_dispatch_result/update_tool_dispatch_result_usecase.dart';
import '../../domain/usecases/tool_dispatch_result/get_tool_dispatch_result_usecase.dart';

void registerToolDispatchResultUseCase(GetIt getIt) {
  getIt.registerLazySingleton<UpdateToolDispatchResultUseCase>(() => UpdateToolDispatchResultUseCase(getIt()));
  getIt.registerLazySingleton<GetToolDispatchResultUseCase>(() => GetToolDispatchResultUseCase(getIt()));
}

// END GENERATED
