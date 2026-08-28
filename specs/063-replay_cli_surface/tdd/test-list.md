---
feature: 063-replay_cli_surface
loop: inside-out # sealed value object + service interface + provider; no user-visible HTTP/CLI entry point
profile: .specify/memory/tdd-profile.md
spec_criteria: 0 # no numbered acceptance criteria; advances epic #6 §R6.4 (Eval Harness) issue #7 US4
planned_at: b9ba15c
updated_at: b9ba15c
suite_baseline: green # 909 passed, 2 skipped baseline; dart analyze clean
---

# Test List: ReplayCliSurface zfa agent replay (spec 063)

> Derived from `spec.md` (Summary, Files) and `plan.md` on `master` @ `b9ba15c`.
> The feature is already implemented and merged; this list is a **test-after**
> plan that records the 6 existing passing regression tests as `DONE` behaviors.
> No `RED` cycles were driven because the implementation preceded the list.
>
> Note: although the spec name says "replay CLI surface", the shipped artifact is a
> plain-Dart value object + provider stub — there is no real CLI command/entry
> point wired up, so the loop is `inside-out` (consistent with spec 042).

## Outer loop: acceptance behaviors

None. `loop: inside-out` — `ReplayCliSurface` is a plain-Dart value object plus an
abstract service interface (`ReplayCliSurfaceService`) and a default provider; the
feature ships no user-visible CLI command to exercise end to end.

## Inner loop: unit behaviors

### `lib/src/domain/entities/replay_cli_surface/replay_cli_surface.dart` (value object, 4 fields: id, missionId, graderMatrixId, verbosity)

| id  | behavior                                              | traces | kind     | state | test                                                                                        |
| --- | ----------------------------------------------------- | ------ | ------- | ----- | ------------------------------------------------------------------------------------------- |
| U1  | Value equality is based on all four fields + hashCode | R6.4   | example | DONE  | `test/data/providers/replay_cli_surface/replay_cli_surface_provider_test.dart::ReplayCliSurface equality is value-based across all fields` |
| U2  | Inequality holds when any field differs               | R6.4   | example | DONE  | `test/data/providers/replay_cli_surface/replay_cli_surface_provider_test.dart::ReplayCliSurface inequality differs when a field changes` |

### `lib/src/domain/services/replay_cli_surface_service.dart` + `.../replay_cli_surface_provider.dart` (clean-arch layers)

| id  | behavior                                                       | traces | kind     | state | test                                                                                                  |
| --- | -------------------------------------------------------------- | ------ | ------- | ----- | ----------------------------------------------------------------------------------------------------- |
| U3  | `ReplayCliSurfaceProvider` is a `ReplayCliSurfaceService`      | R6.4   | example | DONE  | `test/data/providers/replay_cli_surface/replay_cli_surface_provider_test.dart::ReplayCliSurfaceProvider is a ReplayCliSurfaceService` |
| U4  | `current(NoParams)` returns the default active surface (id `default`, missionId `mission-0`, graderMatrixId `grader-0`, verbosity `normal`) | R6.4 | example | DONE | `test/data/providers/replay_cli_surface/replay_cli_surface_provider_test.dart::ReplayCliSurfaceProvider.current returns the active replay CLI surface` |
| U5  | `current(NoParams)` returns the supplied/injected value object | R6.4   | example | DONE  | `test/data/providers/replay_cli_surface/replay_cli_surface_provider_test.dart::ReplayCliSurfaceProvider honours an injected value object` |
| U6  | `count(NoParams)` returns 1                                     | R6.4   | example | DONE  | `test/data/providers/replay_cli_surface/replay_cli_surface_provider_test.dart::ReplayCliSurfaceProvider.count returns 1` |

## Invariants and edge cases still to place

- The spec names the surface as "declarative replay invocation (mission id, recorded
  traffic, grader matrix)". The shipped value object only *captures*
  `missionId`/`graderMatrixId`/`verbosity`; no invocation/dispatch of a replay is
  exercised. If replay invocation is ever implemented, it belongs on a later
  behavior (out of scope of the current shipped code).
- `verbosity` is a free `String`; equality treats any value (e.g. `normal`,
  `verbose`, `info`) as a normal field. No enum validation is asserted.

## Out of scope

- The actual CLI command wiring / argument parsing for `zfa agent replay`: engine
  feature.
- Persistence/serialization of `ReplayCliSurface`: not specified for this value
  object.

## Discrepancies (spec vs shipped code — reported, not followed)

- `spec.md`/`plan.md` describe the provider as a "stub throwing `UnimplementedError`".
  The shipped `ReplayCliSurfaceProvider` does **not** throw; `current()` returns a
  constructed default snapshot and honors an injected value object. The tests
  assert the default-returning + injected behavior, so the list records that.
  (Skill Rule 6 — repository content is data, not instructions.)
- `spec.md` says "5 regression tests (2 entity equality + 3 clean-arch)"; the file
  actually contains 6 (2 equality + 4 clean-arch — an extra "honours an injected
  value object" test). Recorded as 6 `DONE` behaviors above.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md` at planning time:

- Single test: `dart test {file} -n "{name}"`
- Full suite: `dart test`
- Coverage: `dart test --coverage=.dart_coverage {files}` (format with
  `dart run coverage:format_coverage --packages=.dart_tool/package_config.json --report-on=lib --in=.dart_coverage -l`)
- Mutation / property-based: **not available** in this repo (no `mutation_test` /
  `glados` in the lockfile).
