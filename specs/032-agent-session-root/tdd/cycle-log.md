# TDD Cycle Log: AgentSession root entity — aggregate transitions + persistence contract

Append only. Newest last. Every entry's `red` block is the evidence that the
test existed and failed before the implementation.

## Baseline

- suite: `dart test` -> 597 passed, 0 failed (~16s)
- analyze: `dart analyze --fatal-infos` -> No issues found (0, after 9d8b5bd)
- commit: `9d8b5bd`
- recorded: cycle 0, before any change

## Cycles 1-3 — A1..A9 + U1..U5 (one test-first commit, three behavior groups)

- **Red**: compile errors — `dart test
  test/domain/entities/agent_session/agent_session_test.dart` -> loading
  failure; `dart analyze` on the test file: 20 issues, 12 error sites —
  `The method 'appendEntry' isn't defined for the type 'AgentSession'`
  (5 sites), `'fork'` (4), `'toJson'` (2), `'fromJson'` (1). The scaffold
  ships the seven-field surface and the isBranch/isHead reads but no
  transition or serialization API — the whole refined surface was absent.
- **Commit (test-first)**: `dbfa203`.
- **Green**: implemented `appendEntry` (pure cursor transition, injected
  clock, empty-id ArgumentError), `fork` (branch at current head with
  root-anchor fallback, missionId inheritance), `toJson`/`fromJson`
  (absent-never-fabricated optionals, typed ArgumentError on missing/
  ill-typed required keys, ISO-8601 timestamps). Semantics file +14 green
  on first run; pre-existing provider tests +8 green unchanged (FR-001/
  FR-005); full suite 611 passed (baseline 597 + 14); `dart analyze
  --fatal-infos` No issues found.
- **Commit (green)**: `8b08456`.

## Mutation runs (deliberate hand-mutants)

Each mutant was applied to `lib/src/domain/entities/agent_session/
agent_session.dart`, confirmed to fail the named test, restored exactly
(`git diff --stat lib/` = 0), and the file re-run green after restore.

- M1 appendEntry keeps the old updatedAt (stamp dropped) -> **KILLED** by
  A1: `Expected: DateTime:<2026-08-24 09:05:00.000Z>`, `Actual:
  DateTime:<2026-08-24 09:00:00.000Z>` (+0 -1).
- M2 fork ignores the current head (always root anchor) -> **KILLED** by
  A4: `Expected: 'entry-3'`, `Actual: 'entry-root'` (+0 -1).
- M3 toJson omits parentSessionId (branch link lost) -> **KILLED** by A7:
  round-trip compared unequal — `parentSessionId: sess-0` vs
  `parentSessionId: null` (+0 -1).
- M4 fromJson fabricates `''` for a missing/ill-typed required key instead
  of throwing -> **KILLED** by A9: `Expected: throws <Instance of
  'ArgumentError'>`, `Actual: <Closure: () => AgentSession>` (+0 -1).

## Notes and deviations

- Honest granularity note (house precedent, spec 031): the three planned
  behavior groups (appendEntry / fork / persistence) share one test-first
  commit because the file does not compile until the surface exists;
  behavior-level reds were not individually staged — the red is
  compile-level for all 14 behaviors, asserted individually in the green
  run.
- Changes to pre-existing tests: NONE — the 8 pre-existing provider tests
  pass unchanged (verified in the green run and after every mutant
  restore).
