// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#1 (epic — native agent engine) and
// specs/014-planner-todo-system (gap-analysis row 7: Planner/TODO system,
// modeled after dart_agent_core's write_todos tool with PlanState).
//
// PlanMode — operator configuration for the planner. Spec-exact from
// specs/014-planner-todo-system FR-003: "Plan mode MUST be configurable
// (none, auto, must)" and User Story 2.
//
// Pattern: plain Dart enum (no @Zorphy annotation), same as StopPolicy
// (PR #47), AgentTool (PR #52), and SteeringQueue (PR #51).

/// How the engine wires the planner into a mission.
enum PlanMode {
  /// No planner at all — the write_todos tool is not injected; the
  /// model executes without a structured plan.
  none,

  /// Planner tools are available but optional — the model may plan
  /// when a mission benefits from decomposition, and is never forced.
  auto,

  /// Forced planning — the engine injects the planner tools AND
  /// requires a plan before execution starts (SC-002: "planning is
  /// required before executing").
  must;

  /// True for every mode except [none] — controls whether the engine
  /// injects the write_todos tool into the agent (FR-001).
  bool get injectsPlannerTools => this != PlanMode.none;

  /// True only for [must] — the engine must hold execution until the
  /// model has written a plan (SC-002).
  bool get requiresPlanningBeforeExecution => this == PlanMode.must;
}
