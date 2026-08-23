// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/thinking_level_change_entry/thinking_level_change_entry.dart';

abstract class ThinkingLevelChangeEntryDataSource
    with Loggable, FailureHandler {
  Future<ThinkingLevelChangeEntry> get(
    QueryParams<ThinkingLevelChangeEntry> params,
  );
  Future<ThinkingLevelChangeEntry> update(
    UpdateParams<String, ThinkingLevelChangeEntryPatch> params,
  );
}

// END GENERATED
