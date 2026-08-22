/// StopPolicy public API for engine loop safety rails.
///
/// Provides configuration for max turns, wall-clock timeout,
/// and repetition detection to prevent runaway loops.
library;

import '../domain/entities/stop_policy/stop_policy.dart' show StopPolicy;

/// Default stop policy with sensible safety limits.
StopPolicy defaultPolicy() {
  return StopPolicy(
    maxTurns: 100,
    wallClockTimeoutMs: 300000, // 5 minutes
    repetitionThreshold: 3,
    enabled: true,
  );
}

/// Extension adding convenience methods to StopPolicy.
extension StopPolicyExt on StopPolicy {
  /// Creates a copy with modified fields.
  StopPolicy copyWith({
    int? maxTurns,
    int? wallClockTimeoutMs,
    int? repetitionThreshold,
    bool? enabled,
  }) {
    return StopPolicy(
      maxTurns: maxTurns ?? this.maxTurns,
      wallClockTimeoutMs: wallClockTimeoutMs ?? this.wallClockTimeoutMs,
      repetitionThreshold: repetitionThreshold ?? this.repetitionThreshold,
      enabled: enabled ?? this.enabled,
    );
  }
}