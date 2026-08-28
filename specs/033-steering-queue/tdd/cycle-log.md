# TDD Cycle Log: SteeringQueue + SteeringMessage — enqueue/dispatch/inject semantics

Append only. Newest last. Every entry's `red` block is the evidence that the
test existed and failed before the implementation.

## Baseline

- suite: `dart test` -> 611 passed, 0 failed (~28s)
- analyze: `dart analyze --fatal-infos` -> No issues found
- commit: `e9fbc07`
- recorded: cycle 0, before any change

## Cycles 1-3 — A1..A9 + U1..U6 (one test-first commit, three behavior groups)

- **Red**: compile errors — `dart test
  test/domain/entities/steering_queue/steering_queue_test.dart` -> loading
  failure; 17 error sites: `The method 'enqueue' isn't defined for the
  type 'SteeringQueue'` (4), `'pop'` (4), `'toJson'`/`'fromJson'` on both
  value objects (9). The scaffold ships the four-field snapshot and the
  head/isEmpty/pendingCount reads but no transition or serialization API.
- **Commit (test-first)**: `7652487`.
- **Green**: implemented `enqueue` (FIFO append + lastInjectedAt stamp,
  pure snapshot), `pop` (Dart 3 record `({message, queue})`,
  processedCount + 1, lastInjectedAt preserved, StateError naming the
  queue id on empty), defensive immutability (`List.unmodifiable` in the
  constructor — the scaffold stored the caller's reference), and
  `toJson`/`fromJson` on both value objects. Semantics file +15 green on
  first run; pre-existing provider tests +9 green unchanged; full suite
  626 passed (baseline 611 + 15); `dart analyze --fatal-infos` No issues
  found (1 transient unused-variable warning in the test file fixed
  pre-commit, test-side only).
- **Commit (green)**: `cd6c12b`.

## Mutation runs (deliberate hand-mutants)

Each mutant was applied to `lib/src/domain/entities/steering_queue/
steering_queue.dart`, confirmed to fail the named test, restored exactly
(`git diff --stat lib/` = 0), and the file re-run green after restore.

- M1 enqueue keeps the old lastInjectedAt (stamp dropped) -> **KILLED**
  by A1: `Expected: DateTime:<2026-08-24 09:00:00.000Z>`, `Actual:
  <null>` (+0 -1).
- M2 pop drops the processedCount increment (`+ 1` removed) -> **KILLED**
  by A4: `Expected: <4>`, `Actual: <3>` (+0 -1).
- M3 constructor stores the caller's list reference (scaffold behavior —
  defensive copy removed) -> **KILLED** by U1: the smuggled
  source-list mutation leaked in, `Expected: <1>`, `Actual: <2>`
  (+0 -1).
- M4 pop drains LIFO (returns `pending.last` instead of `first`) ->
  **KILLED** by A4: `Expected: SteeringMessage(id: m-1, content:
  first...)`, `Actual: SteeringMessage(id: m-2, content: second...)`
  (+0 -1).

## Notes and deviations

- **Single-test filter trap (recorded for the audit)**: the first M2 run
  was read as a survivor because `dart test -n "A4: pop ... with
  processedCount + 1"` matched NOTHING — the `+` in the test name is a
  regex quantifier, and `dart test -n` exits 0 with "No tests ran."
  (the exact trap `.specify/memory/tdd-profile.md` warns about). Re-run
  with the regex-safe filter `-n "A4"`: mutant properly KILLED. Lesson
  applied: always read the matched-test count, never the exit code.
- Honest granularity note (house precedent, specs 031/032): the three
  planned behavior groups (enqueue / pop / persistence) share one
  test-first commit because the file does not compile until the surface
  exists; behavior-level reds were not individually staged.
- Changes to pre-existing tests: NONE — the 9 pre-existing provider
  tests pass unchanged (verified in the green run and after every
  mutant restore).
