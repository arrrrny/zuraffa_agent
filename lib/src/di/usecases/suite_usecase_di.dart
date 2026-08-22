// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/usecases/engine/score_suite_usecase.dart';
import '../../domain/usecases/engine/evaluate_suite_usecase.dart';

void registerSuiteUseCase(GetIt getIt) {
  getIt.registerLazySingleton<ScoreSuiteUseCase>(() => ScoreSuiteUseCase(getIt()));
  getIt.registerLazySingleton<EvaluateSuiteUseCase>(() => EvaluateSuiteUseCase(getIt()));
}

// END GENERATED