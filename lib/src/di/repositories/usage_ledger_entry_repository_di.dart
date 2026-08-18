// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../data/datasources/usage_ledger_entry/usage_ledger_entry_remote_datasource.dart';
import '../../data/repositories/data_usage_ledger_entry_repository.dart';
import '../../domain/repositories/usage_ledger_entry_repository.dart';

void registerUsageLedgerEntryRepository(GetIt getIt) {
  getIt.registerLazySingleton<UsageLedgerEntryRepository>(
    () => DataUsageLedgerEntryRepository(
      getIt<UsageLedgerEntryRemoteDataSource>(),
    ),
  );
}

// END GENERATED
