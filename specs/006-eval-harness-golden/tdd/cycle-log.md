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

## Cycle: A4 — release gate decision with per-task breakdown

- test: `test/eval/suite_gate_006_a4_test.dart` :: "A4: a suite scoring below the
  gate threshold fails with a per-task breakdown" (plus both sides of the
  threshold boundary and a missing-samples case)
- RED: `dart test test/eval/suite_gate_006_a4_test.dart` ->
  `Error: Undefined name 'SuiteGate'.` — `Suite.gateThreshold` existed as a field
  but nothing turned sample counts into a verdict.
- GREEN: added `lib/src/eval/suite_gate.dart` — `TaskSamples`, `TaskGateResult`,
  `GateDecision`, and `SuiteGate.evaluate`, computing per-task pass@k through the
  existing `PassAtK.compute` estimator, the suite score as their mean, the
  verdict as `score >= gateThreshold`, an `exitCode` of 0/1 for CI, and a report
  string naming each task with its score and verdict. Pure Dart, no `dart:io`
  (FR-005). Full suite green (950 passed, 2 skipped, 68s).
- Design decision forced by the third case: the first implementation let a suite
  with a task that had NO samples still pass, because a 0.0 row only dragged the
  mean. That is exactly the "silently skipped hardest mission" failure the
  acceptance criterion is guarding against, so missing samples now veto the gate
  outright (`incomplete` check) rather than being averaged away. The test was not
  weakened to match the implementation; the implementation was corrected.
- Deliberate mutant: `score >= suite.gateThreshold` -> `score >` -> the
  at-threshold case failed (`Expected: true Actual: <false>`), so the boundary is
  genuinely pinned on both sides. Restored.
- No refactor needed.
- commit: (this cycle)
