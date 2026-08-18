// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/repositories/usage_ledger_entry_repository.dart';
import '../../domain/usecases/usage_ledger_entry/delete_usage_ledger_entry_usecase.dart';

void registerDeleteUsageLedgerEntryUseCase(GetIt getIt) {
  getIt.registerLazySingleton<DeleteUsageLedgerEntryUseCase>(
    () => DeleteUsageLedgerEntryUseCase(getIt<UsageLedgerEntryRepository>()),
  );
}

// END GENERATED
