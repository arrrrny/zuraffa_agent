// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/repositories/usage_ledger_entry_repository.dart';
import '../../domain/usecases/usage_ledger_entry/update_usage_ledger_entry_usecase.dart';

void registerUpdateUsageLedgerEntryUseCase(GetIt getIt) {
  getIt.registerLazySingleton<UpdateUsageLedgerEntryUseCase>(
    () => UpdateUsageLedgerEntryUseCase(getIt<UsageLedgerEntryRepository>()),
  );
}

// END GENERATED
