// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/custom_entry/custom_entry.dart';

abstract class CustomEntryDataSource with Loggable, FailureHandler {
  Future<CustomEntry> get(QueryParams<CustomEntry> params);
  Future<CustomEntry> update(UpdateParams<String, CustomEntryPatch> params);
}

// END GENERATED
