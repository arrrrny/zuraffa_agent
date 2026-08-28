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

## Cycle: A8 — GM-1..GM-5 suite runs in CI and reports/gates correctly

- test: `test/eval/suite_runner_006_a8_test.dart` :: two acceptance cases —
  "A8: GM-1..GM-5 suite — all tasks pass the gate → exitCode 0" and
  "A8: GM-1..GM-5 suite — tasks below threshold fail the gate → exitCode 1".
- RED: written and run after the production path already existed
  (MissionRunner spec 069, CassetteReplayLlmClient A1, SuiteGate A4). First run
  failed to load on three compile errors — `EngineLoopExecutor` not imported and
  `const` applied to non-const fakes (`_OkDispatcher`/`_SearchThenStopPlanner`).
  Those are test-only harness wiring mistakes, not a missing behavior, so they
  were fixed and the test re-run; the proper red for the behavior itself is the
  deliberate-mutant check below.
- GREEN: the two cases drive a `Suite` (tasks GM-1..GM-5, k=2, gateThreshold
  0.8) by running each golden mission n=5 times through a real `MissionRunner`
  backed by `CassetteReplayLlmClient.fromGoldenMission`, grading each replay's
  summary with an exact matcher, and calling `SuiteGate.evaluate`. Passing
  cohort: every task scores pass@k 1.0 → suite score 1.0, passed, exitCode 0.
  Failing cohort: GM-3/GM-4/GM-5 score 0.0, GM-1/GM-2 score 1.0 → suite mean
  0.4 < 0.8, failed, exitCode 1, breakdown names the three regressed tasks. Full
  suite green (952 passed, 2 skipped, 65s). No production code was added or
  changed — this is the end-to-end composition the outer-only plan had left
  BLOCKED ("needs harness runner test").
- Deliberate mutant: `suite_gate.dart` `passed = score >= suite.gateThreshold &&
  !incomplete` -> `passed = false`. The passing-cohort case failed
  (`Expected: true Actual: <false>`); the failing-cohort case still passed (it
  expects false). Restored the line exactly. The test is not vacuous: it pins the
  gate's pass/fail verdict, not just the score.
- No refactor needed (the test isolates a self-contained harness; the runner,
  replay client, and gate are already minimal and shared).
- commit: (this cycle)
