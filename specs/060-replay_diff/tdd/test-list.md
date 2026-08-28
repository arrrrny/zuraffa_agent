---
feature: 060-replay_diff
loop: inside-out # sealed value object + service interface + provider; no user-visible HTTP/CLI entry point
profile: .specify/memory/tdd-profile.md
spec_criteria: 0 # no numbered acceptance criteria; advances epic #6 §R6.1 (Eval Harness) issue #7 US1
planned_at: b9ba15c
updated_at: b9ba15c
suite_baseline: green # 909 passed, 2 skipped baseline; dart analyze clean
---

# Test List: ReplayDiff input drift detection (spec 060)

> Derived from `spec.md` (Summary, Files) and `plan.md` on `master` @ `b9ba15c`.
> The feature is already implemented and merged; this list is a **test-after**
> plan that records the 6 existing passing regression tests as `DONE` behaviors.
> No `RED` cycles were driven because the implementation preceded the list.

## Outer loop: acceptance behaviors

None. `loop: inside-out` — `ReplayDiff` is a plain-Dart value object plus an
abstract service interface (`ReplayDiffService`) and a default provider; there is
no HTTP/CLI/user-visible entry point to exercise end to end.

## Inner loop: unit behaviors

### `lib/src/domain/entities/replay_diff/replay_diff.dart` (value object, 4 fields: id, missionId, driftDetected, diffSummary)

| id  | behavior                                              | traces | kind     | state | test                                                                                  |
| --- | ----------------------------------------------------- | ------ | ------- | ----- | ------------------------------------------------------------------------------------- |
| U1  | Value equality is based on all four fields + hashCode | R6.1   | example | DONE  | `test/data/providers/replay_diff/replay_diff_provider_test.dart::ReplayDiff equality is value-based across all fields` |
| U2  | Inequality holds when any field differs               | R6.1   | example | DONE  | `test/data/providers/replay_diff/replay_diff_provider_test.dart::ReplayDiff inequality differs when a field changes` |

### `lib/src/domain/services/replay_diff_service.dart` + `.../replay_diff_provider.dart` (clean-arch layers)

| id  | behavior                                                       | traces | kind     | state | test                                                                                                |
| --- | -------------------------------------------------------------- | ------ | ------- | ----- | --------------------------------------------------------------------------------------------------- |
| U3  | `ReplayDiffProvider` is a `ReplayDiffService`                  | R6.1   | example | DONE  | `test/data/providers/replay_diff/replay_diff_provider_test.dart::ReplayDiffProvider is a ReplayDiffService` |
| U4  | `current(NoParams)` returns the default active snapshot (id `default`, missionId `mission-0`, driftDetected `false`, diffSummary `null`) | R6.1 | example | DONE | `test/data/providers/replay_diff/replay_diff_provider_test.dart::ReplayDiffProvider.current returns the active replay diff` |
| U5  | `current(NoParams)` returns the supplied/injected value object | R6.1   | example | DONE  | `test/data/providers/replay_diff/replay_diff_provider_test.dart::ReplayDiffProvider honours an injected value object` |
| U6  | `count(NoParams)` returns 1                                     | R6.1   | example | DONE  | `test/data/providers/replay_diff/replay_diff_provider_test.dart::ReplayDiffProvider.count returns 1` |

## Invariants and edge cases still to place

- The spec names `ReplayDiff` as detecting "input drift between record and replay
  (same inputs, different bytes -> flagged)". The shipped value object only
  *captures* `driftDetected` + `diffSummary`; no byte-comparison/detection
  algorithm is exercised. If drift detection is ever implemented, it belongs on a
  later behavior (out of scope of the current shipped code).
- `diffSummary` is nullable; equality treats `null` as a normal field value (both
  sides `null` compare equal). No separate null-vs-empty-string edge case is
  asserted beyond `U1`/`U2`.

## Out of scope

- Engine-side / eval-harness consumption of the replay diff snapshot: eval-harness
  feature.
- Persistence/serialization of `ReplayDiff`: not specified for this value object.

## Discrepancies (spec vs shipped code — reported, not followed)

- `spec.md`/`plan.md` describe the provider as a "stub throwing `UnimplementedError`".
  The shipped `ReplayDiffProvider` does **not** throw; `current()` returns a
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
