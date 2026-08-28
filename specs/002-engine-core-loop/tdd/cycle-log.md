# Cycle Log: Engine Core Loop (spec 002)

Append only. Newest last. This file currently holds only the Baseline entry; no
cycles have been driven yet because `plan.md` is absent and the outer-only TDD
plan is being recorded before any change.

## Baseline

- suite: `dart test` -> 909 passed, 2 skipped (0 failed)
- commit: `fce207d`
- recorded: cycle 0, before any change

## Analysis — spec 069 merge unblocks the outer loop (not a test cycle)

- Decision: merge `feat/spec-069-mission-runner` into `master` (commit `c4805d5`,
  fast-forward-clean from `fec7889`) so the engine core loop (`MissionRunner`)
  exists on `master`. This resolves the TDD-run blocker: previously no multi-turn
  loop existed, and `ChatCompletion` carried no structured tool-call payload.
- `MissionRunner`'s own suite (`test/engine/mission_runner_test.dart`, 543 lines)
  now satisfies `002 A1`, `A6`, `A10` — verified by reading the test bodies, so
  those behaviors are marked `DONE` in `test-list.md` (skill rule: already covered
  by a passing test -> mark DONE, cite the test). Ticked in `tasks.md`.
- Gaps remaining (no passing test satisfies them): `A2` (200-call stress),
  `A3` (determinism), `A4`/`A5` (thinking-block persistence), `A7`
  (follow-up-at-end continuation), `A8` (typed `MaxTurnsExceeded` outcome — 069
  only emits generic `budgetExhausted`), `A9` (repetition/`LoopDetected` wiring).
- suite after merge: `dart test` -> 929 passed, 2 skipped (0 failed).

## Cycle A2 — 200-call mission completes (red -> green)

- test: `test/engine/mission_runner_002_a2_test.dart` :: "A2: a 200-call mission
  completes with no event loss or state corruption"
- RED: new test against `MissionRunner` (spec 069). First run failed for the wrong
  reason — a bug in the test's fake `ScriptedPlanner` returned a tool call on the
  final `stop` turn, so the loop overran the 200-item script and the LLM client
  threw (`providerFailed`). Fixed the fake (`finishReason != 'tool_calls' => []`).
- RED (clean): after the fake fix, the test asserts `turnsUsed == 200`,
  `status == completed`, exact event counts, and transcript growth; passes.
- Deliberate mutant: hard-capped `effectiveMaxTurns = 5` in
  `lib/src/engine/mission_runner.dart` -> A2 failed (`budgetExhausted` !=
  `completed`). Restored; full suite green (930 passed, 2 skipped).
- No refactor needed; fakes duplicated from spec 069's test (candidate for a
  shared helper later).
- commit: `b498e44`
