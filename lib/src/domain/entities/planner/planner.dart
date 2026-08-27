// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#1 (epic — native agent engine) and
// specs/014-planner-todo-system (gap-analysis row 7: Planner/TODO system,
// modeled after dart_agent_core's write_todos tool with PlanState).
//
// Planner — creates the write_todos tool. Spec-exact from
// specs/014-planner-todo-system Key Entities: "Planner: creates
// write_todos tool" and User Story 2 (plan mode).
//
// The Planner is the engine-side seam between configuration and tool
// injection: given a PlanMode it answers (a) whether the write_todos
// tool is injected at all, (b) whether the engine must hold execution
// until a plan exists, and (c) the AgentTool declaration(s) to register.
// It owns no state — the plan state itself lives in PlanState snapshots
// persisted through the PlanStateRepository.
//
// Pattern: plain Dart value object (no @Zorphy annotation), same as
// StopPolicy (PR #47), AgentTool (PR #52), and SteeringQueue (PR #51).

import '../agent_tool/agent_tool.dart';
import 'plan_mode.dart';
import 'write_todos_tool.dart';

/// Creates the write_todos tool and answers plan-mode policy.
class Planner {
  /// The configured plan mode — defaults to [PlanMode.auto] (planner
  /// tools available but optional, User Story 2 acceptance scenario 1).
  final PlanMode mode;

  const Planner({this.mode = PlanMode.auto});

  /// The write_todos AgentTool declaration this planner injects —
  /// always the canonical [WriteTodosTool.declaration].
  AgentTool get writeTodosTool => WriteTodosTool.declaration;

  /// True when [mode] injects planner tools (auto and must, not none).
  bool get injectsWriteTodosTool => mode.injectsPlannerTools;

  /// True when the engine must hold execution until the model has
  /// written a plan (SC-002) — only [PlanMode.must].
  bool get requiresPlanningBeforeExecution =>
      mode.requiresPlanningBeforeExecution;

  /// The AgentTool declarations to register for this mission: the
  /// write_todos tool when the mode injects it, otherwise empty.
  List<AgentTool> toolsForInjection() =>
      injectsWriteTodosTool ? <AgentTool>[writeTodosTool] : const <AgentTool>[];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Planner &&
          runtimeType == other.runtimeType &&
          mode == other.mode);

  @override
  int get hashCode => mode.hashCode;

  @override
  String toString() => 'Planner(mode: $mode)';
}
