part of 'engine_event.dart';

/// Emitted when a mission finishes (success, fail, or cancelled). Pairs with MissionStarted (issue #17). Carries terminal status + optional summary.
final class MissionCompleted extends EngineEvent {
  @override
  final DateTime emittedAt;
  final String missionId;
  final String status;
  final String? summary;

  const MissionCompleted({required this.emittedAt, required this.missionId, required this.status, required this.summary});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MissionCompleted &&
          runtimeType == other.runtimeType &&
          emittedAt == other.emittedAt &&
          missionId == other.missionId &&
          status == other.status &&
          summary == other.summary);

  @override
  int get hashCode => Object.hash(emittedAt, missionId, status, summary);

  @override
  String toString() =>
      'MissionCompleted(emittedAt: $emittedAt, missionId: $missionId, status: $status, summary: $summary)';
}
