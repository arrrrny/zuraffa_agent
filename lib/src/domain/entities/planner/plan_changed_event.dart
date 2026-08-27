// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#1 (epic — native agent engine) and
// specs/014-planner-todo-system (gap-analysis row 7: Planner/TODO system,
// modeled after dart_agent_core's write_todos tool with PlanState).
//
// PlanChangedEvent — emitted whenever the plan changes. Spec-exact from
// specs/014-planner-todo-system FR-005: "Plan changes MUST emit
// PlanChangedEvent".
//
// This is a domain-level event value object: it pairs the previous and
// next PlanState snapshots plus the emission timestamp. Wiring it into
// the sealed EngineEvent union (lib/src/engine/events/) happens with the
// engine-loop spec (045-engine_loop), which owns that library — the
// EngineEvent sealed class forbids subtypes outside its declaring
// library (issues #16–#24), so the union grows only from its own spec.
//
// Pattern: plain Dart value object (no @Zorphy annotation), same as
// StopPolicy (PR #47), AgentTool (PR #52), and SteeringQueue (PR #51).

import 'plan_state.dart';

/// Emitted when the model's write_todos call (or the engine's reset)
/// changes the mission's plan.
class PlanChangedEvent {
  /// When the change was applied.
  final DateTime emittedAt;

  /// The plan snapshot before the change.
  final PlanState previous;

  /// The plan snapshot after the change.
  final PlanState next;

  const PlanChangedEvent({
    required this.emittedAt,
    required this.previous,
    required this.next,
  });

  /// How many more steps are completed in [next] than in [previous].
  /// Positive for progress, negative when steps were reopened, zero
  /// for rewrites that only reshuffle descriptions.
  int get completedGained => next.completedCount - previous.completedCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanChangedEvent &&
          runtimeType == other.runtimeType &&
          emittedAt == other.emittedAt &&
          previous == other.previous &&
          next == other.next);

  @override
  int get hashCode => Object.hash(emittedAt, previous, next);

  @override
  String toString() =>
      'PlanChangedEvent(emittedAt: $emittedAt, completedGained: $completedGained, '
      'previous: $previous, next: $next)';
}
