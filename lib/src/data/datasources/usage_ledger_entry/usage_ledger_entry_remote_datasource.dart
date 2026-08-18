// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/usage_ledger_entry/usage_ledger_entry.dart';
import 'usage_ledger_entry_datasource.dart';

class UsageLedgerEntryRemoteDataSource
    with Loggable, FailureHandler
    implements UsageLedgerEntryDataSource {
  @override
  Future<UsageLedgerEntry> get(QueryParams<UsageLedgerEntry> params) async {
    throw UnimplementedError('Implement remote get');
  }

  @override
  Future<List<UsageLedgerEntry>> getList(
    ListQueryParams<UsageLedgerEntry> params,
  ) async {
    throw UnimplementedError('Implement remote getList');
  }

  @override
  Future<UsageLedgerEntry> create(UsageLedgerEntry usageLedgerEntry) async {
    throw UnimplementedError('Implement remote create');
  }

  @override
  Future<UsageLedgerEntry> update(
    UpdateParams<String, UsageLedgerEntryPatch> params,
  ) async {
    throw UnimplementedError('Implement remote update');
  }

  @override
  Future<void> delete(DeleteParams<String> params) async {
    throw UnimplementedError('Implement remote delete');
  }
}

// END GENERATED
