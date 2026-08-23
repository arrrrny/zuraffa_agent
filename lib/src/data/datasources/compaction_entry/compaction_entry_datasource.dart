// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/compaction_entry/compaction_entry.dart';

abstract class CompactionEntryDataSource with Loggable, FailureHandler {
  Future<CompactionEntry> get(QueryParams<CompactionEntry> params);
  Future<CompactionEntry> update(
    UpdateParams<String, CompactionEntryPatch> params,
  );
}

// END GENERATED
