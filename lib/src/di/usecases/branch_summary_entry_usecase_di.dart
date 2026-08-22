// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/usecases/branch_summary_entry/get_branch_summary_entry_usecase.dart';
import '../../domain/usecases/branch_summary_entry/update_branch_summary_entry_usecase.dart';

void registerBranchSummaryEntryUseCase(GetIt getIt) {
  getIt.registerLazySingleton<GetBranchSummaryEntryUseCase>(() => GetBranchSummaryEntryUseCase(getIt()));
  getIt.registerLazySingleton<UpdateBranchSummaryEntryUseCase>(() => UpdateBranchSummaryEntryUseCase(getIt()));
}

// END GENERATED
