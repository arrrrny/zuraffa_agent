// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/usecases/engine/resolve_agent_spec_usecase.dart';

void registerAgentSpecUseCase(GetIt getIt) {
  getIt.registerLazySingleton<ResolveAgentSpecUseCase>(() => ResolveAgentSpecUseCase(getIt()));
}

// END GENERATED