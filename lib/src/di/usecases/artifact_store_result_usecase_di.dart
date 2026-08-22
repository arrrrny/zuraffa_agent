// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/usecases/artifact_store_result/update_artifact_store_result_usecase.dart';
import '../../domain/usecases/artifact_store_result/get_artifact_store_result_usecase.dart';

void registerArtifactStoreResultUseCase(GetIt getIt) {
  getIt.registerLazySingleton<UpdateArtifactStoreResultUseCase>(() => UpdateArtifactStoreResultUseCase(getIt()));
  getIt.registerLazySingleton<GetArtifactStoreResultUseCase>(() => GetArtifactStoreResultUseCase(getIt()));
}

// END GENERATED
