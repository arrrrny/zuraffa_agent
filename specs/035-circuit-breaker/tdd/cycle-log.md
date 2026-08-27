# TDD Cycle Log: CircuitBreaker state machine — recovery readiness + persistence contract

Append only. Newest last. Every entry's `red` block is the evidence that the
test existed and failed before the implementation.

## Baseline

- suite: `dart test` -> 640 passed, 0 failed (~28s)
- analyze: `dart analyze --fatal-infos` -> No issues found
- commit: `727c618`
- recorded: cycle 0, before any change

## Cycles 1-3 — A1..A9 + U1..U5 (one test-first commit, three behavior groups)

- **Red**: compile errors — `dart test
  test/domain/entities/circuit_breaker/circuit_breaker_test.dart` ->
  loading failure; 23 error sites: `The method 'shouldProbe' isn't
  defined for the type 'CircuitBreaker'` (8 sites), `'toJson'` (7),
  `'fromJson'` (8). The scaffold ships the nine-field snapshot, the three
  transitions, and the state reads, but no recovery-readiness predicate
  and no serialization. A4..A6 (full-cycle characterization) are
  green-on-scaffold BY DESIGN — a regression pin, not a bug fix; their
  red is the same loading red (the file did not compile).
- **Commit (test-first)**: `9b8ed3d`.
- **Green**: implemented `shouldProbe` (read-only, inclusive boundary,
  null-openedAt guard) and `toJson`/`fromJson` (state as name, Duration
  as microseconds, absent-never-fabricated timestamps, parse-time
  threshold validation). Pre-green fixture repairs (test-side only, the
  documented house pattern): three malformed-input JSON fixtures were
  incomplete — missing `failureCount`/`halfOpenSuccesses`, so the strict
  parser failed on the counters before reaching the field under test
  (unknown state, non-positive cooldown, unparseable timestamp); fixtures
  completed. One transient unused-const warning removed. Semantics file
  +14 green; pre-existing provider tests +12 green unchanged; full suite
  654 passed (baseline 640 + 14); `dart analyze --fatal-infos` No issues
  found.
- **Commit (green)**: `24372dc`.

## Mutation runs (deliberate hand-mutants)

Each mutant was applied to `lib/src/domain/entities/circuit_breaker/
circuit_breaker.dart`, run against the named test, restored exactly
(`git diff --stat lib/` = 0), and the file re-run green after restore.

- M1 shouldProbe boundary flips to exclusive (`>` instead of `>=`) ->
  **KILLED** by A2: `Expected: true`, `Actual: <false>` (+0 -1) — the
  inclusive-boundary pin caught it at the exact tick.
- M2 shouldProbe internally calls tryHalfOpen (hidden transition) ->
  **SURVIVED — equivalent-by-design**: CircuitBreaker is an immutable
  snapshot; `tryHalfOpen` returns a NEW instance and the caller's
  reference cannot be mutated, so a discarded internal transition is
  unobservable by construction (the returned boolean is identical). The
  read-only discipline is enforced STRUCTURALLY by immutability, not
  behaviorally. U2 remains as a regression pin for any future refactor
  toward mutability. Documented, not remediated.
- M3 fromJson resets openedAt to parse time (cooldown restarts at
  restore) -> **KILLED** by A8: `Expected: true`, `Actual: <false>`
  (+0 -1) — the restored breaker's cooldown restarted, so shouldProbe at
  the original boundary went false. (First mutant attempt was
  mis-specified — an `?? DateTime.now()` fallback that only affected the
  null-openedAt path and changed nothing for open breakers; corrected to
  the unconditional reset. Recorded for the audit.)
- M4 fromJson defaults an unknown state string to closed -> **KILLED**
  by U3: `Expected: throws ArgumentError with name: 'state'`, `Actual:
  <Closure: () => CircuitBreaker>` (+0 -1) — the silent default caught.

## Notes and deviations

- Honest granularity note (house precedent): the three behavior groups
  share one test-first commit; the red is compile-level for shouldProbe
  and the serialization surface. A4..A6 are characterization tests of
  existing transitions (green-on-scaffold by design — declared in the
  test-list plan and pinned as regression coverage; no false red
  claimed).
- Changes to pre-existing tests: NONE — the 12 pre-existing provider
  tests pass unchanged (verified in the green run and after every mutant
  restore).
