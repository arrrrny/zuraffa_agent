// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/usage_ledger_entry/usage_ledger_entry.dart';

abstract class UsageLedgerEntryDataSource with Loggable, FailureHandler {
  Future<UsageLedgerEntry> get(QueryParams<UsageLedgerEntry> params);
  Future<List<UsageLedgerEntry>> getList(
    ListQueryParams<UsageLedgerEntry> params,
  );
  Future<UsageLedgerEntry> create(UsageLedgerEntry usageLedgerEntry);
  Future<UsageLedgerEntry> update(
    UpdateParams<String, UsageLedgerEntryPatch> params,
  );
  Future<void> delete(DeleteParams<String> params);
}

// END GENERATED
