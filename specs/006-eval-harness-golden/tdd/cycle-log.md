# Cycle Log: Eval Harness — Golden Missions, Record/Replay, pass@k (spec 006)

Append only. Newest last. This file currently holds only the Baseline entry; no
cycles have been driven yet because `plan.md` is absent and the outer-only TDD
plan is being recorded before any change.

## Baseline

- suite: `dart test` -> 909 passed, 2 skipped (0 failed)
- commit: `fce207d`
- recorded: cycle 0, before any change

## Cycle: A1 — cassette replay consumes recordings, not live calls

- test: `test/eval/cassette_replay_006_a1_test.dart` :: "A1: replaying a cassette
  consumes the recordings, never the live client, and reproduces the recorded
  event order"
- RED: `dart test test/eval/cassette_replay_006_a1_test.dart` ->
  `Error when reading 'lib/src/eval/cassette_replay_llm_client.dart': No such
  file or directory` / `Undefined name 'CassetteReplayLlmClient'.` — the repo had
  the `GoldenMission` entity and its cassette struct but no replay execution path.
- GREEN: added `lib/src/eval/cassette_replay_llm_client.dart`: an
  `LlmClientProvider` subclass whose `complete` serves the cassette's
  `completions` in order, exposes `consumed` / `recordingCount` / `exhausted` /
  `liveCallCount`, and throws `StateError` once exhausted so a stale cassette
  fails the eval instead of silently going live. A real `MissionRunner` drives it
  end to end and the emitted event types are compared against the cassette's
  recorded `eventOrder`. Full suite green (947 passed, 2 skipped, 114s).
- Deliberate mutant: `_completions[_cursor++]` -> `_completions[0]` (serve the
  first recording forever, never advancing) -> A1 failed (`Expected: <2>
  Actual: <0>` consumed). Restored.
- No refactor needed.
- commit: (this cycle)
