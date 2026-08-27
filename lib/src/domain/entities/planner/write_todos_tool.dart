// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#1 (epic — native agent engine) and
// specs/014-planner-todo-system (gap-analysis row 7: Planner/TODO system,
// modeled after dart_agent_core's write_todos tool with PlanState —
// attributed port of the tool contract, MIT).
//
// WriteTodosTool — the canonical write_todos AgentTool declaration.
// Spec-exact from specs/014-planner-todo-system FR-001: "A write_todos
// tool MUST be injectable into the agent" and User Story 1.
//
// The declaration is a static const AgentTool value (PR #52's tool value
// object): id "write_todos", RiskTier.safe (rewriting the plan is
// idempotent and side-effect-free), sequential execution, and a JSON
// Schema requiring a `todos` array whose items carry id / content /
// status. The dispatcher validates the call-site payload against the
// schema before the tool runs (R3.1), so the plan state only ever sees
// well-formed step lists.
//
// Pattern: plain Dart declaration (no @Zorphy annotation), same as
// StopPolicy (PR #47), AgentTool (PR #52), and SteeringQueue (PR #51).

import '../agent_tool/agent_tool.dart';

/// The write_todos tool declaration the Planner injects.
final class WriteTodosTool {
  /// The registry id — "write_todos", dart_agent_core's name for the
  /// same surface.
  static const String toolId = 'write_todos';

  /// Human-readable description surfaced in tool-selection prompts to
  /// the model.
  static const String toolDescription =
      'Create or update the mission to-do list. Each todo has a stable '
      'id, a description, and a status (pending, in_progress, completed, '
      'cancelled). Calling this tool replaces the current plan; use it '
      'to plan before executing and to keep progress accurate.';

  /// JSON Schema for the call-site payload: a required `todos` array
  /// of {id, content, status} objects. Status strings mirror
  /// StepStatus names (pending / in_progress / completed / cancelled).
  static const Map<String, dynamic> paramsSchema = {
    'type': 'object',
    'properties': {
      'todos': {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'id': {'type': 'string'},
            'content': {'type': 'string'},
            'status': {
              'type': 'string',
              'enum': ['pending', 'in_progress', 'completed', 'cancelled'],
            },
          },
          'required': ['id', 'content', 'status'],
        },
      },
    },
    'required': ['todos'],
  };

  /// The injectable AgentTool declaration. The Planner hands this to
  /// the tool registry; the engine dispatches against it by id.
  static const AgentTool declaration = AgentTool(
    id: toolId,
    description: toolDescription,
    riskTier: RiskTier.safe,
    executionMode: ExecutionMode.sequential,
    paramsSchema: paramsSchema,
  );

  const WriteTodosTool._();
}
