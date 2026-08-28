---
feature: 015-engine-event-json-part
loop: inside-out # part directive + placeholder part file; a library structural addition, no entry point
profile: .specify/memory/tdd-profile.md
spec_criteria: 0 # no numbered acceptance scenarios; short PR-style spec (Closes #15)
planned_at: fce207d
updated_at: fce207d
suite_baseline: green # 909 passed, 2 skipped
---

# Test List: EngineEvent json_serializable part directive (spec 015)

> Derived from `spec.md` (Summary, Files, Verification) and `plan.md` on `master` @
> `fce207d`. The feature is already implemented and merged; this is a **test-after** plan
> recording the structural change as `DONE` behaviors. No `RED` cycles were driven because
> the implementation preceded the list.

## Outer loop: acceptance behaviors

None. `loop: inside-out` — adding a `part` directive and a placeholder part file is a
library-internal structural change with no HTTP/CLI/user-visible entry point. Its required
outcome (the directive is present and the library compiles) is verified by package
compilation, not by an end-to-end test.

## Inner loop: unit behaviors

### `lib/src/engine/events/engine_event.dart` + `lib/src/engine/events/engine_event.g.dart`

| id  | behavior                                                                                                                              | traces        | kind             | state | test                                                                                  |
| --- | ------------------------------------------------------------------------------------------------------------------------------------- | ------------- | ---------------- | ----- | ------------------------------------------------------------------------------------- |
| U1  | `engine_event.dart` carries the `part 'engine_event.g.dart';` directive after the 9 existing subtype `part` directives (structure matches the zfa generator's intended output) | Summary, Files | characterization | DONE  | `test/engine/events/engine_event_test.dart` (whole package compiles; `switch over EngineEvent is exhaustive with all current subtypes`) |
| U2  | `engine_event.g.dart` exists, declares `part of 'engine_event.dart';`, and compiles so the `part` directive resolves (placeholder reserved for future json_serializable output) | Summary, Files | characterization | DONE  | `test/engine/events/engine_event_test.dart` (package compiles green with the new part file) |

## Invariants and edge cases still to place

- The placeholder `.g.dart` is intentionally empty until `@Zorphy` annotations are added to
  the `EngineEvent` subtypes; no behavior is expected from it yet. No further line required.

## Out of scope

- Actual `json_serializable` codegen (`_$XFromJson`/`_$XToJson`): requires `@Zorphy` on the
  subtypes (future work; zfa generator fix).
- Wiring `PlanChangedEvent` into the `EngineEvent` union: owned by the engine-loop spec (045).

## Discrepancies (spec vs shipped code — reported, not followed)

- `spec.md` states "All 156 tests still pass" (the older baseline count at the time of the
  PR). The current suite baseline is 909 passed / 2 skipped — the count evolved; the
  directive still resolves and the package compiles clean. No behavioral conflict.
- There is no dedicated unit test that asserts the literal `part` directive text; the
  requirement is enforced structurally by `dart analyze` + package compilation (a broken
  `part` directive would fail the whole package to compile, so every other test would be
  blocked). The `engine_event_test.dart` suite is recorded as the regression gate.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md` at planning time:

- Single test: `dart test {file} -n "{name}"`
- Full suite: `dart test`
- Coverage: `dart test --coverage=.dart_coverage {files}` (format with
  `dart run coverage:format_coverage --packages=.dart_tool/package_config.json --report-on=lib --in=.dart_coverage -l`)
- Mutation / property-based: **not available** in this repo (no `mutation_test` /
  `glados` in the lockfile).
