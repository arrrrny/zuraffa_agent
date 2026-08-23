// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/label_entry/label_entry.dart';

abstract class LabelEntryDataSource with Loggable, FailureHandler {
  Future<LabelEntry> get(QueryParams<LabelEntry> params);
  Future<LabelEntry> update(UpdateParams<String, LabelEntryPatch> params);
}

// END GENERATED
