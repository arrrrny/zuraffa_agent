// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/usecases/agent_tool/get_agent_tool_usecase.dart';
import '../../domain/usecases/agent_tool/update_agent_tool_usecase.dart';
import '../../domain/usecases/agent_tool/toggle_agent_tool_usecase.dart';

void registerAgentToolUseCase(GetIt getIt) {
  getIt.registerLazySingleton<GetAgentToolUseCase>(() => GetAgentToolUseCase(getIt()));
  getIt.registerLazySingleton<UpdateAgentToolUseCase>(() => UpdateAgentToolUseCase(getIt()));
  getIt.registerLazySingleton<ToggleAgentToolUseCase>(() => ToggleAgentToolUseCase(getIt()));
}

// END GENERATED