# Feature Specification: MissionRunner (multi-turn mission loop)

**Branch**: `feat/spec-069-mission-runner` | **Date**: 2026-08-29

## Summary

Deliver the keystone runtime the repo's own headers call for: a multi-turn
mission loop that composes the existing engine pieces — `EngineLoopExecutor`
(spec 045, the atomic LLM turn), `ToolDispatcher` (spec 003/047 interface),
`StopPolicy` (spec 002/027), `SteeringQueue` (spec 033) — and **emits the
EngineEvent union** (issues #16–#24) through an injected sink. Until now the
event types were orphaned: nothing in `lib/` constructed them at runtime, and
`EngineLoopExecutor`'s own header admits "multi-turn looping (tool dispatch,
stop policies, steering drain) is composed by the caller" — but no such caller
existed anywhere. This spec is that caller.

GAP-ANALYSIS row 12 ("Event Bus … EngineEvent sealed hierarchy only … limited
observability") and row 1 ("Core Engine Loop … Equivalent" — true only for
single turns) both trace to this missing composition.

### Design constraint discovered during analysis

`ChatCompletion` (spec 051) carries `content` / `reasoning` / `finishReason` /
`usage` — **no structured tool-call payload**. The loop therefore cannot parse
"which tools does the model want" out of the completion with current types.
Rather than inventing a text protocol or extending the completion VO (a
separate concern), this spec introduces the `ToolCallPlanner` seam: an injected
strategy that maps a completion + transcript to a list of `ToolCall`s (the
currency type already defined in `lib/src/engine/tool_dispatcher.dart`).
Tests supply deterministic planners; a real LLM-tool-call parser plugs in when
the completion VO grows tool-call fields. The loop's continuation signal is
`finishReason`: `'stop'` + no tool calls ends the mission naturally; anything
else continues (model-driven, per the EngineLoop doc: "the model drives").

## Files

- `lib/src/engine/mission_runner.dart` — NEW: `MissionStatus` enum
  (`completed`, `budgetExhausted`, `providerFailed`), `MissionResult` value
  object (house pattern), `ToolCallPlanner` interface, `MissionRunner`.
- `test/engine/mission_runner_test.dart` — NEW: fakes
  (`FakeLlmClient`, `FakeToolDispatcher`, scripted planners) + the spec-069
  suite.
- `specs/069-mission-runner/{spec,plan,tasks}.md` + `tdd/{test-list,verification}.md`.

Not exported from `lib/zuraffa_agent.dart` — consistent with the sibling
engine runtimes (`tool_dispatcher.dart`, `agent_hooks.dart`,
`agent_hook_pipeline.dart`, none of which are barrel-exported).

## FRs

- **FR-001** — `MissionRunner.run({missionId, messages, planner?})` emits, in
  order: `MissionStarted(emittedAt, missionId, startedAt)` … per turn:
  `SteeringInjected` per drained message (when a queue was supplied),
  `TurnStarted(emittedAt, turnId: '$missionId-turn-$n')`, then
  `ToolCallStarted`/`ToolCallCompleted` per dispatched call (tool dispatch
  happens INSIDE the turn), then `TurnCompleted` … and finally
  `MissionCompleted(emittedAt, missionId, status: <status>.name, summary?)`
  exactly once, whatever the outcome. A provider-failed turn emits NO
  `TurnCompleted` (the turn never finished). All timestamps come from an
  injectable `clock` (default `DateTime.now`) — deterministic tests, no
  ambient time.
- **FR-002** — Natural completion: when a turn's `finishReason == 'stop'` and
  the planner produced no tool calls, the mission stops with
  `MissionStatus.completed`; `MissionResult.summary` is that turn's assistant
  content; the assistant message is appended to the returned transcript.
- **FR-003** — Tool dispatch: each planned `ToolCall` is dispatched
  sequentially through the injected `ToolDispatcher`
  (`isInternalMission: false`); a `tool`-role `ChatMessage` carrying the
  result (success: `ToolDispatchResult.result`, failure:
  `ToolDispatchResult.error`) is appended to the transcript; `ToolCallStarted`
  and `ToolCallCompleted` share a `callId` of the form
  `'$missionId-call-$turn-$index'`; `ToolCallCompleted.ok` mirrors
  `ToolDispatchResult.success`; a failed tool does NOT abort the mission.
- **FR-004** — Steering drain: when constructed with a `SteeringQueue`, all
  pending messages are drained at the START of each turn (FIFO via `pop()`),
  each appended to the transcript as a `user` message and announced with
  `SteeringInjected(emittedAt, content, injectedAt: message.injectedAt)`. The
  queue instance is never mutated in place; the drained snapshot replaces it.
- **FR-005** — Budgets (from `StopPolicy`, when `enabled`): effective turn cap
  is `min(executor.loop.maxTurns, stopPolicy.maxTurns)` — reaching it stops
  the mission with `budgetExhausted` (the executor's `StateError` backstop
  never fires because the runner checks first). When
  `wallClockTimeout != Duration.zero`, a deadline of
  `start + wallClockTimeout` is checked before each turn; exceeding it stops
  with `budgetExhausted`. When `enabled == false`, only the executor's
  `loop.maxTurns` applies.
- **FR-006** — Provider failure: if `executor.runTurn` throws, the runner
  emits `ProviderError(emittedAt, providerName: executor.llmClient.config.id,
  error: e.toString())`, stops with `MissionStatus.providerFailed`, and still
  emits the terminal `MissionCompleted` (a mission never ends without its
  terminal event).
- **FR-007** — `MissionResult` carries value semantics (spec 066 house
  pattern): `==`/`hashCode` over `(missionId, status, turnsUsed, transcript,
  summary)` with element-wise transcript comparison, and a `toString`
  rendering the id, status, turns, and message count.
- **FR-008** — Gates: `dart analyze --fatal-infos` clean; `dart test` green
  (baseline 915 passed / 2 skipped at `fec7889` + new tests).

## Verification

- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — baseline + new tests pass, 0 new failures

## Out of scope

- Tool-call parsing from real LLM responses (`ChatCompletion` has no
  tool-call fields yet — the `ToolCallPlanner` seam is the integration point).
- Repetition threshold enforcement (needs `RepetitionTracker` wiring — future
  spec; `StopPolicy.repetitionThreshold` is carried but not enforced here).
- Session-tree persistence of the transcript (`AgentSession` integration).
- Wiring `ThinkingDelta` / `PlanChanged` emission (streaming + planner specs).
- Sub-agent execution on top of the loop (spec 070), goal-based stopping
  (spec 071), swarm orchestration (spec 072) — stacked follow-ups.
