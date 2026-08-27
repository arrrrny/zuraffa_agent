// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#25.
//
// The RepetitionTracker value object. Tracks per-tool invocation repetition
// within a window; emits a signal when a tool has been called more than N
// times in the last M seconds (spec 002 US4 — loop safety rails).
//
// Refined under specs/25-repetition_tracker-datasource-pair (TDD cycle 1):
// the policy surface is id + maxCalls (N) + window (M) plus the pure
// isRepetition predicate; the mutable per-signature history lives behind
// the RepetitionTrackerDatasource contract (see the mock implementation).
//
// Declared as a plain Dart value object (no @Zorphy annotation) so the file
// compiles without running build_runner. When zfa ships a consistent
// value-object generator, this file may be regenerated with @Zorphy; until
// then it is the canonical source for the RepetitionTracker surface.

/// RepetitionTracker value object.
///
/// Loop-detection policy for the engine loop: a signature looping means it
/// was recorded at least [maxCalls] times within the trailing [window].
/// The predicate is pure — call sites feed it the live in-window count
/// observed through a [RepetitionTrackerDatasource].
class RepetitionTracker {
  /// Logical identifier for the tracker (e.g. "default", "conservative").
  final String id;

  /// Maximum number of in-window occurrences (N) before the signature is
  /// considered looping. Inclusive: the [maxCalls]-th occurrence trips the
  /// signal. Must be >= 1.
  final int maxCalls;

  /// Trailing window (M) within which occurrences are counted. Occurrences
  /// exactly [window] old are expired; strictly younger ones are alive.
  final Duration window;

  const RepetitionTracker({
    required this.id,
    this.maxCalls = 5,
    this.window = const Duration(seconds: 60),
  }) : assert(maxCalls >= 1, 'maxCalls must be >= 1 (got $maxCalls)');

  /// True when [observedCalls] in-window occurrences meet the loop
  /// threshold: `observedCalls >= maxCalls`.
  bool isRepetition(int observedCalls) => observedCalls >= maxCalls;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RepetitionTracker &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          maxCalls == other.maxCalls &&
          window == other.window);

  @override
  int get hashCode => Object.hash(id, maxCalls, window);

  @override
  String toString() =>
      'RepetitionTracker(id: $id, maxCalls: $maxCalls, window: $window)';
}
