# Implementation Plan: MissionRunner

**Branch**: `feat/spec-069-mission-runner` | **Date**: 2026-08-29

## Summary

Compose the existing engine value objects into the first real multi-turn
runtime. Pure dependency-injected loop: LLM turns via `EngineLoopExecutor`,
tools via the `ToolDispatcher` interface (fakes in tests — the repo has no
production impl yet, which is fine: the runner codes against the interface),
stop conditions via `StopPolicy`, steering via `SteeringQueue` snapshots,
events via an injected `void Function(EngineEvent)` sink, time via an
injectable clock.

## Phase 1 — Design

### `lib/src/engine/mission_runner.dart` (new)

```dart
enum MissionStatus { completed, budgetExhausted, providerFailed }

class MissionResult { /* missionId, status, turnsUsed, transcript, summary;
                         == / hashCode (Object.hashAll for transcript) / toString */ }

abstract interface class ToolCallPlanner {
  Future<List<ToolCall>> plan(ChatCompletion completion, List<ChatMessage> transcript);
}

class MissionRunner {
  MissionRunner({
    required EngineLoopExecutor executor,
    required ToolDispatcher toolDispatcher,
    required StopPolicy stopPolicy,
    SteeringQueue? steeringQueue,
    required void Function(EngineEvent) onEvent,
    DateTime Function()? clock,
  });

  Future<MissionResult> run({
    required String missionId,
    required List<ChatMessage> messages,
    ToolCallPlanner? planner,
  });
}
```

Loop skeleton (per spec FRs): emit `MissionStarted` → while(true):
budget/deadline checks (`budgetExhausted`) → drain steering (FR-004) →
`TurnStarted` → `runTurn` in try/catch (`ProviderError` + `providerFailed`,
FR-006) → append assistant msg → `TurnCompleted` → planner → sequential
dispatch loop with `ToolCallStarted`/`ToolCallCompleted` + `tool`-role
appends (FR-003) → natural-stop check (FR-002) → terminal `MissionCompleted`.

Effective turn cap: `stopPolicy.enabled
? min(executor.loop.maxTurns, stopPolicy.maxTurns)
: executor.loop.maxTurns` (FR-005). Deadline checked before each turn.

### Test doubles (`test/engine/mission_runner_test.dart`)

- `ScriptedLlmClient extends LlmClientProvider` — returns a queue of
  `ChatCompletion`s, optionally throws, optionally advances a fake clock.
- `FakeToolDispatcher implements ToolDispatcher` — records dispatches,
  returns scripted `ToolDispatchResult`s.
- `ScriptedPlanner implements ToolCallPlanner` — completion-indexed tool
  calls.
- Fixed `clock` (`DateTime.utc(2026, 1, 1)` + manual increments) → exact
  `emittedAt` assertions.

## Phase 2 — TDD

1. RED: whole test file first against the missing
   `mission_runner.dart` (compile failure = evidence).
2. GREEN: implement until the file passes.
3. Deliberate mutants (one at a time, `cp`-restore, never `git checkout` on
   uncommitted work): M1 drop `MissionStarted` emission; M2 don't append the
   tool result to the transcript; M3 turn-cap off-by-one (`>=` → `>`);
   M4 drain steering once instead of per turn; M5 `ToolCallCompleted.ok`
   hardcoded `true`.
4. Gates: `dart analyze --fatal-infos`; full `dart test`; record real counts.
5. `tdd/verification.md` with honest verdict; commit artifacts WITH code;
   push; PR.

## Risks / notes

- `EngineLoopExecutor.runTurn` throws `StateError` past the cap — the runner
  pre-checks, so the backstop is unreachable in practice; M3 must show the
  pre-check is load-bearing.
- `ToolDispatchResult` is a Zorphy entity — construct via its generated
  constructor; check the generated shape before writing fakes.
- Provider name for `ProviderError`: `executor.llmClient.config.id` (both
  fields public; no extra constructor knob).
