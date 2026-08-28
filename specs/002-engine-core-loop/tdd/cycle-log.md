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

## Cycle A3 — determinism (red -> green)

- test: `test/engine/mission_runner_002_a3_test.dart` :: "A3: 10 identical runs
  produce a byte-identical event stream"
- RED: new test drives MissionRunner 10x with an injected FIXED clock and asserts
  every run yields the identical serialized event stream (exhaustive field-key
  switch over the sealed EngineEvent union) and identical MissionResult. Passes
  first run (behavior already implemented).
- Deliberate mutant: changed `final start = _clock()` to `DateTime.now()` in
  `lib/src/engine/mission_runner.dart` -> run 1's MissionStarted timestamp diverged
  from run 0 ("stream diverged") -> test failed. Restored; full suite green
  (931 passed, 2 skipped).
- No refactor needed.
- commit: `503ca33`

## Cycle A8 — typed MaxTurnsExceeded outcome at the turn cap (red -> green)

- test: `test/engine/mission_runner_002_a8_test.dart` :: "A8: maxTurns=5 with a
  non-stopping model ends in MaxTurnsExceeded after turn 5"
- RED: new test drives `MissionRunner` with `maxTurns=5` and a planner that always
  asks for a tool call, so the loop can only terminate on the turn cap. Asserts
  `turnsUsed == 5`, `result.status.name == 'maxTurnsExceeded'`, and the terminal
  `MissionCompleted.status == 'maxTurnsExceeded'`. First run FAILED: the engine
  emitted the generic `budgetExhausted` status (069's turn-cap path), so
  `result.status.name` was `'budgetExhausted'` != `'maxTurnsExceeded'`.
- GREEN: added a dedicated `MissionStatus.maxTurnsExceeded` enum value and set the
  turn-cap branch in `lib/src/engine/mission_runner.dart` to it (the wall-clock
  deadline path keeps `budgetExhausted`). `MissionCompleted.status` already
  serializes `status.name`, so the event now carries `maxTurnsExceeded` too.
  Aligned the spec 069 test at `test/engine/mission_runner_test.dart` to expect
  `maxTurnsExceeded` (previously asserted the now-removed `maxTurnsExhausted`
  name). Test passes; full suite green (932 passed, 2 skipped).
- Deliberate mutant: reverted the turn-cap branch to `budgetExhausted` ->
  A8 failed (`budgetExhausted` != `maxTurnsExceeded`). Restored.
- No refactor needed.
- commit: (this cycle)

## Cycle: A9 — LoopDetected on repeated identical tool calls

- test: `test/engine/mission_runner_002_a9_test.dart` :: "A9: maxCalls=3 with a
  repeating tool call ends in loopDetected after the 3rd"
- RED: `dart test test/engine/mission_runner_002_a9_test.dart` ->
  `Error: No named parameter with the name 'repetitionTracker'.` — the engine had
  no repetition seam at all, so the mission could only end on the turn cap.
- GREEN: added `MissionStatus.loopDetected`; `MissionRunner` now accepts an
  optional `RepetitionTrackerDatasource` and, after each dispatched call, records
  `'<toolName>|<arguments>'` and re-evaluates `isLooping`. Tripping the threshold
  breaks the dispatch loop, emits `TurnCompleted`, and ends the mission with
  `loopDetected`. Test passes; full suite green (940 passed, 2 skipped, 57s).
- Deliberate mutant: `looping = true` -> `looping = false` at the trip site ->
  A9 failed. Restored.
- No refactor needed: the guard is 10 lines inside the existing dispatch loop and
  reuses spec 011's datasource contract unchanged.
- commit: (this cycle)

## Cycle: A4 — assistant message carries its thinking block

- test: `test/engine/mission_runner_002_a4_test.dart` :: "A4: a completed turn
  leaves the assistant message carrying its thinking block next to the tool result"
- RED: `dart test test/engine/mission_runner_002_a4_test.dart` ->
  `Error: The getter 'thinking' isn't defined for the type 'ChatMessage'.` — the
  transcript's assistant message had no place to hold reasoning, so a thinking
  model's blocks were dropped at turn completion.
- GREEN: added the nullable `thinking` field to `ChatMessage` (in `==`, `hashCode`,
  and emitted from `toJson` only when present, so messages without reasoning
  serialize exactly as before) and populated it in `MissionRunner` from
  `ChatCompletion.reasoning`, which already carried the provider's thinking text.
  Full suite green (943 passed, 2 skipped, 52s).
- Deliberate mutant: `thinking: completion.reasoning` -> `thinking: null` ->
  A4 failed (`Expected: '...' Actual: <null>`). Restored.
- No refactor needed.
- commit: (this cycle)

## Cycle: A5 — prior turns' thinking blocks survive into turn N+1's context

- test: `test/engine/mission_runner_002_a5_test.dart` :: "A5: turn 2's assembled
  context still carries turn 1's thinking block"
- RED: the test PASSED on its first run (`dart test
  test/engine/mission_runner_002_a5_test.dart` -> `+1: All tests passed!`),
  because A4's `thinking` field lives on the transcript and the transcript *is*
  the context handed to the next turn. Per the playbook this triggers the
  deliberate-mutant check instead of a red.
- Deliberate mutant: `thinking: completion.reasoning` -> `thinking: null` in
  `MissionRunner` -> A5 failed with `Expected: 'Turn one reasoning: ...'
  Actual: <null>` on the turn-2 context assertion. Restored; A5 green again.
  The test is not a tautology of A4: it asserts against the message list the
  client actually received on turn 2 (recorded by the double), plus the wire
  form via `toJson`, so a future "strip reasoning before the next call" step
  would fail A5 while A4 stayed green.
- GREEN: no production change needed for this behavior.
- No refactor needed.
- Full suite green (944 passed, 2 skipped, 48s).
- commit: (this cycle)
