// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/usecases/artifact_ref/get_artifact_ref_usecase.dart';
import '../../domain/usecases/artifact_ref/update_artifact_ref_usecase.dart';

void registerArtifactRefUseCase(GetIt getIt) {
  getIt.registerLazySingleton<GetArtifactRefUseCase>(() => GetArtifactRefUseCase(getIt()));
  getIt.registerLazySingleton<UpdateArtifactRefUseCase>(() => UpdateArtifactRefUseCase(getIt()));
}

// END GENERATED
