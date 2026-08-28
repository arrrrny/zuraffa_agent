// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// Spec 071 — goal mode.
//
// Goal-aware early stopping for the MissionRunner (spec 069): a mission can
// carry a Goal plus an injected GoalEvaluator and stop EARLY — terminal
// status MissionStatus.goalAchieved — the moment the evaluator judges the
// goal met from the transcript so far.
//
// Semantics (deliberate, documented in specs/071-goal-mode/spec.md):
// goal mode is an early-stop overlay, NOT an override. It never extends a
// mission past the model's natural stop, never overrides budgets, and
// never re-prompts. The runner consults the evaluator AFTER each turn's
// tool dispatch (so it sees tool results) and BEFORE the natural-stop
// check (so a goal met on the model's final turn still reports
// goalAchieved). A "strict" re-prompting mode is future work.
//
// No new EngineEvent subtypes: goal achievement surfaces through the
// terminal MissionCompleted.status string only (the sealed union grows
// only from its own spec — issues #16-#24 / spec 067 precedent).
//
// Not exported from lib/zuraffa_agent.dart — consistent with the sibling
// engine runtimes.

import '../domain/entities/llm_client/chat_message.dart';

/// A mission goal: what the mission is trying to achieve.
///
/// Deliberately minimal — `id` + `description`. The evaluator decides what
/// "achieved" means; the goal itself is just the declarative target (the
/// same split as SubAgentSpec's declarative surface vs. the dispatch
/// runtime, specs 036/070).
class Goal {
  final String id;

  /// Human-readable statement of the goal (what the evaluator judges
  /// against; also what an LLM-as-judge prompt would be built from).
  final String description;

  const Goal({required this.id, required this.description});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Goal &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          description == other.description);

  @override
  int get hashCode => Object.hash(id, description);

  @override
  String toString() => 'Goal(id: $id, description: $description)';
}

/// Strategy deciding whether [Goal] is achieved from the mission
/// transcript so far.
///
/// Rule-based in tests; an LLM-as-judge implementation plugs in behind the
/// same seam. The [transcript] handed to [isAchieved] is an unmodifiable
/// view — evaluators must not mutate the mission's working transcript.
abstract interface class GoalEvaluator {
  bool isAchieved(Goal goal, List<ChatMessage> transcript);
}
