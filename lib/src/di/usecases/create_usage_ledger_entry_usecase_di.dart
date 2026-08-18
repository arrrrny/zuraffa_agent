// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/repositories/usage_ledger_entry_repository.dart';
import '../../domain/usecases/usage_ledger_entry/create_usage_ledger_entry_usecase.dart';

void registerCreateUsageLedgerEntryUseCase(GetIt getIt) {
  getIt.registerLazySingleton<CreateUsageLedgerEntryUseCase>(
    () => CreateUsageLedgerEntryUseCase(getIt<UsageLedgerEntryRepository>()),
  );
}

// END GENERATED
