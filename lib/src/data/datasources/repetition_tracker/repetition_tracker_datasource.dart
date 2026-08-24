// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issues arrrrny/zuraffa_agent#25 (uri_does_not_exist) and
// arrrrny/zuraffa_agent#26 (implements_non_class).
//
// Root cause: `zfa make <Entity> ... datasource` in value-object mode emits
// the mock datasource (`repetition_tracker_mock_datasource.dart`) that imports this file
// and `implements RepetitionTrackerDatasource`, but value-object mode SKIPS emitting
// the datasource file itself — the mock references a file zfa itself decided
// not to emit. The fix surface: ship a hand-curated datasource interface so
// the mock_datasource's import + implements clause resolve.

import 'package:zuraffa/zuraffa.dart';
import '../../../domain/entities/repetition_tracker/repetition_tracker.dart';

/// Data-source interface for the RepetitionTracker value object.
///
/// Tracks per-tool invocation repetition within a window; emits a signal when a tool has been called more than N times in the last M seconds.
abstract class RepetitionTrackerDatasource with Loggable, FailureHandler {
  /// Returns the current state of the RepetitionTracker (single instance — value object).
  Future<RepetitionTracker> current();

  /// Resets the RepetitionTracker state to its initial value.
  Future<void> reset();
}
