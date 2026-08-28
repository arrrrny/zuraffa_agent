# Implementation Plan: Goal mode

**Branch**: `feat/spec-071-goal-mode` | **Date**: 2026-08-29

## Summary

A goal-aware early-stop overlay for the MissionRunner: `Goal` +
`GoalEvaluator` in a new library, a new terminal status, two new result
fields, and one evaluation point wired between tool dispatch and the
natural-stop check.

## Phase 1 — Design

### `lib/src/engine/goal_mode.dart` (new)

```dart
class Goal {
  final String id;
  final String description;
  const Goal({required this.id, required this.description});
  // == / hashCode / toString (spec 066 house pattern)
}

abstract interface class GoalEvaluator {
  /// [transcript] is an unmodifiable view of the mission transcript so far.
  bool isAchieved(Goal goal, List<ChatMessage> transcript);
}
```

No imports beyond `chat_message.dart` — no cycle with `mission_runner.dart`.

### `mission_runner.dart` edits

1. `enum MissionStatus { ..., goalAchieved }`.
2. `MissionResult`: `final Goal? goal; final bool goalAchieved;` (defaults
   null / false), folded into `==`/`hashCode`/`toString`.
3. `run()` params: `Goal? goal, GoalEvaluator? goalEvaluator` —
   `ArgumentError` when exactly one is supplied.
4. Evaluation point, after `_onEvent(TurnCompleted(...))` and before the
   natural-stop `if`:

```dart
if (goal != null &&
    goalEvaluator!.isAchieved(goal, List<ChatMessage>.unmodifiable(transcript))) {
  status = MissionStatus.goalAchieved;
  summary = completion.content;
  break;
}
```

### Test doubles (`test/engine/goal_mode_test.dart`)

Local re-declarations of the spec-069 fake shapes (`ScriptedLlmClient`,
`FakeToolDispatcher`, `ScriptedPlanner`) + rule-based evaluators
(`AssistantPresentEvaluator`, `ToolResultPresentEvaluator`,
`TranscriptLengthEvaluator`) and a counting evaluator wrapper.

## Phase 2 — TDD

1. RED: test file first (missing `goal_mode.dart` + missing
   `goalAchieved` enum value / result fields → compile failure).
2. GREEN: implement until green; re-run the spec-069 file explicitly to
   prove the `MissionResult` surface extension broke nothing.
3. Deliberate mutants (cp-restored): M1 evaluation moved before tool
   dispatch; M2 status not set to `goalAchieved` (stays `completed`);
   M3 `goalAchieved` flag never set true; M4 evaluator consulted only on
   turn 1; M5 both-or-neither validation removed.
4. Gates + `tdd/verification.md`; commit; push; PR (base
   `feat/spec-069-mission-runner` — stacked sibling of 070).
