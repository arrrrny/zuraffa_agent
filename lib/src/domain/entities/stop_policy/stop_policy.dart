// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issues arrrrny/zuraffa_agent#13 and arrrrny/zuraffa_agent#27.
//
// The StopPolicy value object. Spec-exact surface from
// specs/002-engine-core-loop/data-model.md: maxTurns (int), wallClockTimeout
// (Duration), repetitionThreshold (int), enabled (bool). zfa v6.0.0 cannot
// generate this surface because it rejects Duration as a field type
// (issue #13), so the file ships hand-curated in the consuming repo.
//
// Declared as a plain Dart value object (no @Zorphy annotation) so the file
// compiles without running build_runner. When zfa ships Duration support
// (or a sealed/value-object-aware generator), this file may be regenerated
// with @Zorphy; until then it is the canonical source for the StopPolicy
// surface.

/// StopPolicy value object.
///
/// Policy surface for the engine loop's stop conditions: max turns, wall-clock
/// timeout, repetition threshold, and a global enabled flag. Producers
/// produce typed StopOutcome outcomes when these conditions are met.
class StopPolicy {
  /// Logical identifier for the policy (e.g. "default", "conservative").
  final String id;

  /// Maximum number of engine turns before the mission auto-stops.
  final int maxTurns;

  /// Hard wall-clock timeout for the entire mission. Duration.zero means
  /// no wall-clock limit (only maxTurns applies).
  final Duration wallClockTimeout;

  /// Maximum number of repetitions of the same tool call within
  /// [repetitionWindowSeconds] before the loop stops the mission.
  final int repetitionThreshold;

  /// Master switch; when false, the policy is inert (no stop conditions
  /// fire, mission runs to natural completion or external cancel).
  final bool enabled;

  const StopPolicy({
    required this.id,
    required this.maxTurns,
    required this.wallClockTimeout,
    required this.repetitionThreshold,
    this.enabled = true,
  });

  /// Canonical default policy — the single source of truth for the values
  /// documented on `StopPolicyService.defaultPolicy` and the reset target
  /// of every `StopPolicyDatasource` implementation.
  static const StopPolicy defaultPolicy = StopPolicy(
    id: 'default',
    maxTurns: 100,
    wallClockTimeout: Duration.zero,
    repetitionThreshold: 5,
    enabled: true,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StopPolicy &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          maxTurns == other.maxTurns &&
          wallClockTimeout == other.wallClockTimeout &&
          repetitionThreshold == other.repetitionThreshold &&
          enabled == other.enabled);

  @override
  int get hashCode => Object.hash(
        id,
        maxTurns,
        wallClockTimeout,
        repetitionThreshold,
        enabled,
      );

  @override
  String toString() =>
      'StopPolicy(id: $id, maxTurns: $maxTurns, wallClockTimeout: $wallClockTimeout, '
      'repetitionThreshold: $repetitionThreshold, enabled: $enabled)';
}
