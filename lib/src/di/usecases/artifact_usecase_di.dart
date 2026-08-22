// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/usecases/artifact/update_artifact_usecase.dart';
import '../../domain/usecases/artifact/get_artifact_usecase.dart';

void registerArtifactUseCase(GetIt getIt) {
  getIt.registerLazySingleton<UpdateArtifactUseCase>(() => UpdateArtifactUseCase(getIt()));
  getIt.registerLazySingleton<GetArtifactUseCase>(() => GetArtifactUseCase(getIt()));
}

// END GENERATED
