// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/usecases/stop_policy/update_stop_policy_usecase.dart';
import '../../domain/usecases/stop_policy/get_stop_policy_usecase.dart';

void registerStopPolicyUseCase(GetIt getIt) {
  getIt.registerLazySingleton<UpdateStopPolicyUseCase>(() => UpdateStopPolicyUseCase(getIt()));
  getIt.registerLazySingleton<GetStopPolicyUseCase>(() => GetStopPolicyUseCase(getIt()));
}

// END GENERATED
