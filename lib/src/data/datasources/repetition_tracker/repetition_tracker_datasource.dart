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
//
// Refined under specs/25-repetition_tracker-datasource-pair: the interface
// now carries the full persistence contract (record / count / isLooping with
// injectable time) so a Hive- or remote-backed implementation can replace
// the mock without touching the engine loop.

import 'package:zuraffa/zuraffa.dart';
import '../../../domain/entities/repetition_tracker/repetition_tracker.dart';

/// Data-source interface for the RepetitionTracker value object.
///
/// Tracks per-tool invocation repetition within a window; a signature is
/// looping when it has been recorded at least `maxCalls` times within the
/// trailing `window` (see [RepetitionTracker.isRepetition]).
///
/// The [signature] parameter is the opaque content-addressable key of a tool
/// or LLM call (the canonical form a `ToolCallSignature` from spec 29
/// produces). This pair deliberately consumes it as a plain `String` so the
/// two specs stay independently testable.
abstract class RepetitionTrackerDatasource with Loggable, FailureHandler {
  /// Returns the current RepetitionTracker configuration (single instance —
  /// value object).
  Future<RepetitionTracker> current();

  /// Records one occurrence of [signature] at [at] (defaults to the
  /// implementation's clock) and returns the post-record in-window count for
  /// that signature — a single round-trip read-after-write.
  Future<int> record(String signature, {DateTime? at});

  /// Returns how many occurrences of [signature] are alive inside the
  /// trailing window, evaluated at [now] (defaults to the implementation's
  /// clock).
  Future<int> count(String signature, {DateTime? now});

  /// Returns whether [signature] is looping at [now]: always derived as
  /// `current().isRepetition(count(signature))` — never sticky.
  Future<bool> isLooping(String signature, {DateTime? now});

  /// Clears every recorded signature history while preserving the
  /// configuration returned by [current].
  Future<void> reset();
}
