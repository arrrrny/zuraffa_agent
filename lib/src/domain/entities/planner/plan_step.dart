// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#1 (epic — native agent engine) and
// specs/014-planner-todo-system (gap-analysis row 7: Planner/TODO system,
// modeled after dart_agent_core's write_todos tool with PlanState).
//
// PlanStep — one entry in the mission's to-do list. Spec-exact from
// specs/014-planner-todo-system Key Entities: "PlanStep: description,
// status". An `id` is added so steps can be addressed immutably across
// turns (the write_todos payload carries stable ids).
//
// Modeled as an immutable value object with a pure copyWith transition
// (CircuitBreaker pattern): status changes return a NEW step, the
// original is never mutated in place.
//
// Pattern: plain Dart value object (no @Zorphy annotation), same as
// StopPolicy (PR #47), AgentTool (PR #52), and SteeringQueue (PR #51).

import 'step_status.dart';

/// A single to-do entry in a plan.
class PlanStep {
  /// Stable identifier for this step, unique within the plan. The
  /// write_todos tool payload addresses steps by id so a step keeps its
  /// identity across turns even when its description is rewritten.
  final String id;

  /// Human-readable description of what this step accomplishes.
  final String description;

  /// Lifecycle status of the step. Defaults to [StepStatus.pending] —
  /// the write_todos tool creates steps that start queued.
  final StepStatus status;

  const PlanStep({
    required this.id,
    required this.description,
    this.status = StepStatus.pending,
  });

  /// True when the step is finished one way or another (completed or
  /// cancelled) — delegates to [StepStatus.isTerminal].
  bool get isTerminal => status.isTerminal;

  /// Returns a new [PlanStep] with the given fields replaced. The
  /// receiver is untouched — status transitions are pure.
  PlanStep copyWith({String? id, String? description, StepStatus? status}) =>
      PlanStep(
        id: id ?? this.id,
        description: description ?? this.description,
        status: status ?? this.status,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanStep &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          description == other.description &&
          status == other.status);

  @override
  int get hashCode => Object.hash(id, description, status);

  @override
  String toString() =>
      'PlanStep(id: $id, description: $description, status: $status)';
}
