// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/repetition_tracker/repetition_tracker.dart';

abstract class RepetitionTrackerDataSource with Loggable, FailureHandler {
  Future<RepetitionTracker> get(QueryParams<RepetitionTracker> params);
  Future<RepetitionTracker> update(
    UpdateParams<String, RepetitionTrackerPatch> params,
  );
}

// END GENERATED
