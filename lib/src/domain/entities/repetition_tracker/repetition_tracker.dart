// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#25.
//
// The RepetitionTracker value object. Tracks per-tool invocation repetition within a window; emits a signal when a tool has been called more than N times in the last M seconds.
//
// Declared as a plain Dart value object (no @Zorphy annotation) so the file
// compiles without running build_runner. When zfa ships a consistent
// value-object generator, this file may be regenerated with @Zorphy; until
// then it is the canonical source for the RepetitionTracker surface.

/// RepetitionTracker value object.
///
/// Tracks per-tool invocation repetition within a window; emits a signal when a tool has been called more than N times in the last M seconds.
class RepetitionTracker {
  final String id;

  const RepetitionTracker({required this.id});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RepetitionTracker && runtimeType == other.runtimeType && id == other.id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'RepetitionTracker(id: $id)';
}
