// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#27.
//
// The StopPolicy value object. Policy surface for the engine loop's stop conditions: max turns, wall-clock timeout, token budget, repetition threshold. Producers produce typed StopOutcome outcomes.
//
// Declared as a plain Dart value object (no @Zorphy annotation) so the file
// compiles without running build_runner. When zfa ships a consistent
// value-object generator, this file may be regenerated with @Zorphy; until
// then it is the canonical source for the StopPolicy surface.

/// StopPolicy value object.
///
/// Policy surface for the engine loop's stop conditions: max turns, wall-clock timeout, token budget, repetition threshold. Producers produce typed StopOutcome outcomes.
class StopPolicy {
  final String id;

  const StopPolicy({required this.id});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StopPolicy && runtimeType == other.runtimeType && id == other.id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'StopPolicy(id: $id)';
}
