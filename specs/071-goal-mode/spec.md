# Feature Specification: Goal mode

**Branch**: `feat/spec-071-goal-mode` (stacked on `feat/spec-069-mission-runner`, PR #80) | **Date**: 2026-08-29

## Summary

Give missions a goal: instead of running purely on budget caps and the
model's natural stop, a mission can carry a `Goal` plus an injected
`GoalEvaluator` and stop EARLY — with terminal status `goalAchieved` — the
moment the evaluator judges the goal met from the transcript so far.

Semantics chosen deliberately (and documented as such): goal mode is an
**early-stop overlay, not an override**. It never extends a mission past
the model's natural stop, never overrides budgets, and never re-prompts.
The evaluator is consulted AFTER each turn's tool dispatch (so it sees tool
results) and BEFORE the natural-stop check (so a goal met on the model's
final turn still reports `goalAchieved`, not `completed`). A
"strict" goal mode that re-prompts until the goal is met is future work —
this spec delivers the honest, composable core.

There is no goal concept anywhere in the repo today (`goal` appears only in
prose in three old spec task files); the closest primitives are budget-only
(`StopPolicy`) and plan-state (`PlanState`), neither of which expresses
"run until X is true about the transcript".

## Files

- `lib/src/engine/goal_mode.dart` — NEW: `Goal` value object (house
  pattern), `GoalEvaluator` interface.
- `lib/src/engine/mission_runner.dart` — EDIT: `MissionStatus` gains
  `goalAchieved`; `MissionResult` gains `goal` + `goalAchieved` fields
  (value semantics extended); `run()` gains `goal`/`goalEvaluator`
  parameters (both-or-neither, `ArgumentError` otherwise) and the
  post-tool/pre-natural-stop evaluation point.
- `test/engine/goal_mode_test.dart` — NEW: the spec-071 suite.
- `specs/071-goal-mode/{spec,plan,tasks}.md` + `tdd/{test-list,verification}.md`.

## FRs

- **FR-001** — `Goal` is a house-pattern value object: `id` + `description`,
  with `==`/`hashCode`/`toString`.
- **FR-002** — `GoalEvaluator` is the injected strategy:
  `bool isAchieved(Goal goal, List<ChatMessage> transcript)`. Rule-based in
  tests; an LLM-as-judge implementation plugs in behind the same seam. The
  transcript handed to the evaluator is an unmodifiable view.
- **FR-003** — `run(goal: g, goalEvaluator: e)` (both or neither —
  `ArgumentError` naming the mismatch otherwise). With goal mode active,
  after each turn's tool dispatch and `TurnCompleted` emission, and BEFORE
  the natural-stop check, the runner consults the evaluator; a `true`
  verdict stops the mission with `MissionStatus.goalAchieved`, `summary`
  set to that turn's assistant content, and `MissionCompleted.status ==
  'goalAchieved'`.
- **FR-004** — Result surface: `MissionResult.goal` (the goal when goal
  mode ran, else null) and `MissionResult.goalAchieved` (true only on the
  `goalAchieved` terminal path; false when goal mode ran but the mission
  ended any other way; false when goal mode was inactive). Value semantics
  (`==`/`hashCode`/`toString`) extended accordingly.
- **FR-005** — Ordering guarantees, load-bearing and mutation-tested:
  (a) evaluation happens AFTER tool dispatch within the turn (an evaluator
  keyed on tool results fires on the SAME turn they land);
  (b) evaluation happens BEFORE the natural-stop check (a goal met on the
  model's `stop` turn reports `goalAchieved`, not `completed`);
  (c) the evaluator is consulted once per completed turn (a provider-failed
  turn is never evaluated);
  (d) budgets still win — goal mode never overrides `budgetExhausted`.
- **FR-006** — No new `EngineEvent` subtypes: goal achievement surfaces
  through the terminal `MissionCompleted.status` string only (the sealed
  union grows only from its own spec, per issues #16–#24 / spec 067
  precedent).
- **FR-007** — Gates: `dart analyze --fatal-infos` clean; `dart test` green
  (baseline 925/2 at `8a5bd83` + new tests; the spec-069 suite must stay
  green through the `MissionResult` surface extension).

## Verification

- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — baseline + new tests pass, 0 new failures

## Out of scope

- Strict goal mode (re-prompting until the goal is met) — needs prompt
  synthesis policy; the early-stop core here is the prerequisite.
- An LLM-as-judge evaluator implementation (the seam accepts it later).
- Persisting goals on `AgentSession` / mission records.
- A goal-specific event subtype (FR-006 documents why not).
