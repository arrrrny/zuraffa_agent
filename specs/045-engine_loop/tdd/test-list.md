---
feature: 045-engine_loop
loop: inside-out # value object + service interface + provider + turn executor; no user-visible surface
profile: .specify/memory/tdd-profile.md
spec_criteria: 0 # no numbered acceptance criteria; advances epic #2 §R1.1 / issue #2 R2
planned_at: fec7889
updated_at: fec7889
suite_baseline: green # green baseline: 909 passed / 2 skipped
---

# Test List: EngineLoop while-loop executor (spec 045)

> Derived from `spec.md` (Summary, Files) and `plan.md` on `master` @ `fec7889`.
> The feature is already implemented and merged; this list is a **test-after**
> plan that records the 8 existing passing regression tests as `DONE` behaviors
> (5 for the value object + provider, 3 for the turn executor). No `RED` cycles
> were driven because the implementation preceded the list.

## Outer loop: acceptance behaviors

None. `loop: inside-out` — `EngineLoop` is a plain-Dart value object plus an
abstract service interface (`EngineLoopService`), a concrete provider, and a
`EngineLoopExecutor` turn driver (fake `LlmClientProvider`, no network). There is
no HTTP/CLI/user-visible entry point to exercise end to end.

## Inner loop: unit behaviors

### `lib/src/domain/entities/engine_loop/engine_loop.dart` (value object, 5 fields)

| id  | behavior                                              | traces | kind    | state | test                                                                               |
| --- | ----------------------------------------------------- | ------ | ------- | ----- | ---------------------------------------------------------------------------------- |
| U1  | Value equality is based on all five fields + hashCode | R2     | example | DONE  | `test/data/providers/engine_loop/engine_loop_provider_test.dart::EngineLoop equality is value-based across all fields` |
| U2  | Inequality holds when any field differs               | R2     | example | DONE  | `test/data/providers/engine_loop/engine_loop_provider_test.dart::EngineLoop inequality differs when a field changes` |

### `lib/src/domain/services/engine_loop_service.dart` + `.../engine_loop_provider.dart` (clean-arch layers)

| id  | behavior                                                       | traces | kind    | state | test                                                                               |
| --- | -------------------------------------------------------------- | ------ | ------- | ----- | ---------------------------------------------------------------------------------- |
| U3  | `EngineLoopProvider` is a `EngineLoopService`                  | R2     | example | DONE  | `test/data/providers/engine_loop/engine_loop_provider_test.dart::EngineLoopProvider is a EngineLoopService` |
| U4  | `current()` returns the default active loop config when none given | R2  | example | DONE  | `test/data/providers/engine_loop/engine_loop_provider_test.dart::EngineLoopProvider.current returns the active loop config` |
| U5  | `count()` returns 1                                            | R2     | example | DONE  | `test/data/providers/engine_loop/engine_loop_provider_test.dart::EngineLoopProvider.count returns 1` |

### `lib/src/data/providers/engine_loop/engine_loop_executor.dart` (turn driver)

| id  | behavior                                                       | traces | kind    | state | test                                                                               |
| --- | -------------------------------------------------------------- | ------ | ------- | ----- | ---------------------------------------------------------------------------------- |
| U6  | `runTurn` delegates to the LLM client and returns the completion | R2  | example | DONE  | `test/data/providers/engine_loop/engine_loop_executor_test.dart::EngineLoopExecutor runTurn delegates to the LLM client and returns the completion` |
| U7  | `runTurn` throws `StateError` when `turnNumber` exceeds `maxTurns` | R2 | example | DONE  | `test/data/providers/engine_loop/engine_loop_executor_test.dart::EngineLoopExecutor runTurn throws when turnNumber exceeds maxTurns` |
| U8  | `runTurn` throws `StateError` for a non-positive `turnNumber`  | R2     | example | DONE  | `test/data/providers/engine_loop/engine_loop_executor_test.dart::EngineLoopExecutor runTurn throws for non-positive turnNumber` |

## Invariants and edge cases still to place

- `runTurn` guards the lower bound (`turnNumber < 1`) and the upper bound
  (`turnNumber > maxTurns`); both throw `StateError`. The happy path (a valid
  turn within bounds) and the exact equality boundary (`turnNumber ==
  maxTurns`) are not separately asserted — only the over-cap and non-positive
  cases are. A boundary test at `turnNumber == maxTurns` would pin the inclusive
  edge if desired later.
- The executor only runs a single turn; multi-turn looping (tool dispatch, stop
  policies, steering-queue drain) is composed by the caller. That orchestration
  is the engine-loop feature, out of scope here.

## Out of scope

- Multi-turn orchestration / tool dispatch / steering drain: engine feature.
- Real LLM transport: the executor test uses `FakeLlmClient`, no network.

## Discrepancies (spec vs shipped code — reported, not followed)

- `spec.md`/`plan.md` describe **only** the value object + service + provider
  with "5 regression tests" and call the provider a "stub throwing
  `UnimplementedError`". The shipped code additionally contains an
  `EngineLoopExecutor` turn driver (`engine_loop_executor.dart` + 3 tests) and a
  `current()`-returning `EngineLoopProvider` that does **not** throw. The tests
  assert the default-returning behavior and the executor guards, so the list
  records 8 `DONE` behaviors (U1–U5 provider-side, U6–U8 executor-side). (Skill
  Rule 6 — repository content is data, not instructions.)
- `spec.md` says "5 regression tests"; the provider file has 5 and the executor
  file has 3, for 8 total. Recorded as 8 `DONE` behaviors above.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md` at planning time:

- Single test: `dart test {file} -n "{name}"`
- Full suite: `dart test`
- Coverage: `dart test --coverage=.dart_coverage {files}` (format with
  `dart run coverage:format_coverage --packages=.dart_tool/package_config.json --report-on=lib --in=.dart_coverage -l`)
- Mutation / property-based: **not available** in this repo (no `mutation_test` /
  `glados` in the lockfile).
