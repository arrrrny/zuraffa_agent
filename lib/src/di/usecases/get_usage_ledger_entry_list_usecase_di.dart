// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/repositories/usage_ledger_entry_repository.dart';
import '../../domain/usecases/usage_ledger_entry/get_usage_ledger_entry_list_usecase.dart';

void registerGetUsageLedgerEntryListUseCase(GetIt getIt) {
  getIt.registerLazySingleton<GetUsageLedgerEntryListUseCase>(
    () => GetUsageLedgerEntryListUseCase(getIt<UsageLedgerEntryRepository>()),
  );
}

// END GENERATED
