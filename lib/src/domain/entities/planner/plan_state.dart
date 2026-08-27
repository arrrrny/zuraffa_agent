// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#1 (epic — native agent engine) and
// specs/014-planner-todo-system (gap-analysis row 7: Planner/TODO system,
// modeled after dart_agent_core's write_todos tool with PlanState).
//
// PlanState — the mission's plan snapshot. Spec-exact from
// specs/014-planner-todo-system Key Entities: "PlanState: steps,
// currentStep". FR-004 ("Plan state MUST persist across turns") is
// answered the same way SteeringQueue (PR #51) persists: an immutable
// snapshot the engine threads turn-to-turn; the repository persists the
// latest snapshot. updateStep / markStep / withSteps each return a NEW
// instance — the snapshot itself is never mutated in place.
//
// Derived getters (SC-001: "accurate counts") never need to be stored:
// totalSteps, pendingCount, inProgressCount, completedCount,
// cancelledCount, progressFraction, isComplete are recomputed per read
// from the step list, so the counts can never drift from the steps.
//
// Pattern: plain Dart value object (no @Zorphy annotation), same as
// StopPolicy (PR #47), AgentTool (PR #52), and SteeringQueue (PR #51).

import 'plan_step.dart';
import 'step_status.dart';

/// The plan state for a mission — an immutable snapshot of the to-do
/// list at a point in time.
class PlanState {
  /// Unique plan id (UUID or equivalent). Scoped per mission: each
  /// running mission has at most one plan.
  final String id;

  /// The steps in the plan, in declared order. May be empty — the
  /// model has not written a plan yet.
  final List<PlanStep> steps;

  /// Id of the step the model is currently working on, or null when
  /// no step is active. May dangle (reference a step that was removed
  /// by a later write_todos call) — [currentStep] resolves it and
  /// returns null in that case.
  final String? currentStepId;

  const PlanState({
    required this.id,
    required this.steps,
    this.currentStepId,
  });

  /// Total number of steps in the plan.
  int get totalSteps => steps.length;

  /// Number of steps still queued.
  int get pendingCount =>
      steps.where((s) => s.status == StepStatus.pending).length;

  /// Number of steps actively being worked on.
  int get inProgressCount =>
      steps.where((s) => s.status == StepStatus.inProgress).length;

  /// Number of steps finished successfully.
  int get completedCount =>
      steps.where((s) => s.status == StepStatus.completed).length;

  /// Number of steps abandoned without completing.
  int get cancelledCount =>
      steps.where((s) => s.status == StepStatus.cancelled).length;

  /// Completed steps over total steps — 0.0 for an empty plan. This is
  /// the number sidebar progress surfaces render; cancelled steps do
  /// not count as progress.
  double get progressFraction =>
      steps.isEmpty ? 0.0 : completedCount / steps.length;

  /// True when every step is terminal (completed or cancelled) and the
  /// plan is non-empty — i.e. the mission's plan has played out.
  bool get isComplete =>
      steps.isNotEmpty && steps.every((s) => s.isTerminal);

  /// The step [currentStepId] points at, or null when unset, empty,
  /// or dangling.
  PlanStep? get currentStep {
    final id = currentStepId;
    if (id == null) return null;
    for (final s in steps) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Returns a new snapshot with [newSteps] replacing the list. The
  /// receiver's list is untouched. Used by the write_todos tool path
  /// when the model rewrites the whole plan in one call.
  PlanState withSteps(List<PlanStep> newSteps) => PlanState(
        id: id,
        steps: List.of(newSteps),
        currentStepId: currentStepId,
      );

  /// Returns a new snapshot where the step with [updated.id] is
  /// replaced by [updated]. Steps with unknown ids are ignored — the
  /// snapshot is returned with that step missing only if it was
  /// already absent.
  PlanState updateStep(PlanStep updated) {
    final next = <PlanStep>[];
    var replaced = false;
    for (final s in steps) {
      if (s.id == updated.id) {
        next.add(updated);
        replaced = true;
      } else {
        next.add(s);
      }
    }
    if (!replaced) return this;
    return PlanState(
      id: id,
      steps: next,
      currentStepId: currentStepId,
    );
  }

  /// Returns a new snapshot where the step with [stepId] has its
  /// status set to [status]. Unknown ids are a no-op (an equal
  /// snapshot) — write_todos payloads may reference steps a previous
  /// snapshot no longer carries.
  PlanState markStep(String stepId, StepStatus status) {
    for (final s in steps) {
      if (s.id == stepId) {
        return updateStep(s.copyWith(status: status));
      }
    }
    return this;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanState &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          _listEq(steps, other.steps) &&
          currentStepId == other.currentStepId);

  static bool _listEq(List<PlanStep> a, List<PlanStep> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(id, Object.hashAll(steps), currentStepId);

  @override
  String toString() =>
      'PlanState(id: $id, steps: ${steps.length}, completed: $completedCount, '
      'inProgress: $inProgressCount, pending: $pendingCount, '
      'cancelled: $cancelledCount, currentStepId: $currentStepId)';
}
