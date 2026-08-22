// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/usecases/usage_ledger_entry/update_usage_ledger_entry_usecase.dart';
import '../../domain/usecases/usage_ledger_entry/get_usage_ledger_entry_usecase.dart';
import '../../domain/usecases/usage_ledger_entry/create_usage_ledger_entry_usecase.dart';
import '../../domain/usecases/usage_ledger_entry/get_usage_ledger_entry_list_usecase.dart';
import '../../domain/usecases/usage_ledger_entry/delete_usage_ledger_entry_usecase.dart';

void registerUsageLedgerEntryUseCase(GetIt getIt) {
  getIt.registerLazySingleton<UpdateUsageLedgerEntryUseCase>(() => UpdateUsageLedgerEntryUseCase(getIt()));
  getIt.registerLazySingleton<GetUsageLedgerEntryUseCase>(() => GetUsageLedgerEntryUseCase(getIt()));
  getIt.registerLazySingleton<CreateUsageLedgerEntryUseCase>(() => CreateUsageLedgerEntryUseCase(getIt()));
  getIt.registerLazySingleton<GetUsageLedgerEntryListUseCase>(() => GetUsageLedgerEntryListUseCase(getIt()));
  getIt.registerLazySingleton<DeleteUsageLedgerEntryUseCase>(() => DeleteUsageLedgerEntryUseCase(getIt()));
}

// END GENERATED
