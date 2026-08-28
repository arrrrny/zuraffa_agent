part of 'engine_event.dart';

// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See specs/067-engine-event-plan-changed (closes the wiring gap left open
// by spec 014 FR-005: "Plan changes MUST emit PlanChangedEvent" — the
// domain value object landed in PR for spec 014, but the sealed union
// forbids subtypes outside its declaring library, so the wiring had to
// grow from this library's own spec, per the contract documented in
// plan_changed_event.dart's header).

/// Emitted when the mission's plan changes (spec 014 FR-005). Carries the
/// domain [PlanChangedEvent] payload pairing the previous/next `PlanState`
/// snapshots.
///
/// `emittedAt` is when the ENGINE emitted this event;
/// `change.emittedAt` is when the plan change was APPLIED — two distinct
/// instants.
final class PlanChanged extends EngineEvent {
  /// When the engine emitted this event.
  @override
  final DateTime emittedAt;

  /// The domain plan-change payload (previous/next `PlanState` snapshots).
  final PlanChangedEvent change;

  const PlanChanged({required this.emittedAt, required this.change});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanChanged &&
          runtimeType == other.runtimeType &&
          emittedAt == other.emittedAt &&
          change == other.change);

  @override
  int get hashCode => Object.hash(emittedAt, change);

  @override
  String toString() => 'PlanChanged(emittedAt: $emittedAt, change: $change)';
}
