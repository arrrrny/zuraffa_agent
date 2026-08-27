// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#1 (epic — native agent engine) and
// specs/014-planner-todo-system (gap-analysis row 7: Planner/TODO system,
// modeled after dart_agent_core's write_todos tool with PlanState).
//
// StepStatus — the lifecycle of a single PlanStep. Spec-exact from
// specs/014-planner-todo-system FR-002: "Plan state MUST track steps with
// status (pending, in_progress, completed, cancelled)".
//
// Pattern: plain Dart enum (no @Zorphy annotation) so the file compiles
// without running build_runner, same as StopPolicy (PR #47), AgentTool
// (PR #52), and SteeringQueue (PR #51).

/// Lifecycle status of a [PlanStep] in a plan.
enum StepStatus {
  /// Not started yet — the step is queued behind the current one.
  pending,

  /// The model is actively working on this step right now.
  inProgress,

  /// The step finished successfully.
  completed,

  /// The step was abandoned (superseded, de-scoped, or failed) — it no
  /// longer blocks plan completion but does not count as progress.
  cancelled;

  /// True for [completed] and [cancelled] — the step will never
  /// transition again. A plan is complete when every step is terminal.
  bool get isTerminal => this == StepStatus.completed || this == StepStatus.cancelled;
}
