// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/usecases/engine/execute_sub_agent_usecase.dart';

void registerSubAgentTypeUseCase(GetIt getIt) {
  getIt.registerLazySingleton<ExecuteSubAgentUseCase>(() => ExecuteSubAgentUseCase(getIt()));
}

// END GENERATED