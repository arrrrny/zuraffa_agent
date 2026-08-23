// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/branch_summary_entry/branch_summary_entry.dart';

abstract class BranchSummaryEntryDataSource with Loggable, FailureHandler {
  Future<BranchSummaryEntry> get(QueryParams<BranchSummaryEntry> params);
  Future<BranchSummaryEntry> update(
    UpdateParams<String, BranchSummaryEntryPatch> params,
  );
}

// END GENERATED
