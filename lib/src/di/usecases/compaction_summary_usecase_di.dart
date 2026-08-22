// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/usecases/compaction_summary/get_compaction_summary_usecase.dart';
import '../../domain/usecases/compaction_summary/update_compaction_summary_usecase.dart';

void registerCompactionSummaryUseCase(GetIt getIt) {
  getIt.registerLazySingleton<GetCompactionSummaryUseCase>(() => GetCompactionSummaryUseCase(getIt()));
  getIt.registerLazySingleton<UpdateCompactionSummaryUseCase>(() => UpdateCompactionSummaryUseCase(getIt()));
}

// END GENERATED
