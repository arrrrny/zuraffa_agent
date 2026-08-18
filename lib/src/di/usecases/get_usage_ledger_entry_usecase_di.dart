// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/repositories/usage_ledger_entry_repository.dart';
import '../../domain/usecases/usage_ledger_entry/get_usage_ledger_entry_usecase.dart';

void registerGetUsageLedgerEntryUseCase(GetIt getIt) {
  getIt.registerLazySingleton<GetUsageLedgerEntryUseCase>(
    () => GetUsageLedgerEntryUseCase(getIt<UsageLedgerEntryRepository>()),
  );
}

// END GENERATED
