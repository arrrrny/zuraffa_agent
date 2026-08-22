// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/usecases/artifact_service_config/update_artifact_service_config_usecase.dart';
import '../../domain/usecases/artifact_service_config/get_artifact_service_config_usecase.dart';

void registerArtifactServiceConfigUseCase(GetIt getIt) {
  getIt.registerLazySingleton<UpdateArtifactServiceConfigUseCase>(() => UpdateArtifactServiceConfigUseCase(getIt()));
  getIt.registerLazySingleton<GetArtifactServiceConfigUseCase>(() => GetArtifactServiceConfigUseCase(getIt()));
}

// END GENERATED
