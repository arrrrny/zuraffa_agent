part of 'engine_event.dart';

/// Emitted when a mission begins. Pairs with MissionCompleted (issue #16).
/// Carries the mission spec id + startedAt.
final class MissionStarted extends EngineEvent {
  @override
  final DateTime emittedAt;

  /// The mission identifier.
  final String missionId;

  /// The started at.
  final DateTime startedAt;

  /// Creates a mission started.
  const MissionStarted({
    required this.emittedAt,
    required this.missionId,
    required this.startedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MissionStarted &&
          runtimeType == other.runtimeType &&
          emittedAt == other.emittedAt &&
          missionId == other.missionId &&
          startedAt == other.startedAt);

  @override
  int get hashCode => Object.hash(emittedAt, missionId, startedAt);

  @override
  String toString() =>
      'MissionStarted(emittedAt: $emittedAt, missionId: $missionId, '
      'startedAt: $startedAt)';
}
