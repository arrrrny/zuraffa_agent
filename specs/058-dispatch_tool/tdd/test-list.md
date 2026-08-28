---
feature: 058-dispatch_tool
loop: inside-out # plain-Dart value object + service interface + provider; no user-visible HTTP/CLI surface
profile: .specify/memory/tdd-profile.md
spec_criteria: 0 # no numbered acceptance criteria; advances epic #5 §R5.4 (issue #6 US4)
planned_at: b9ba15c
updated_at: b9ba15c
suite_baseline: green # 909 passed, 2 skipped; dart analyze clean
---

# Test List: DispatchTool built-in (spec 058)

> Derived from `spec.md` (Summary, Files) and `plan.md` on `master` @ `b9ba15c`.
> The feature is already implemented and merged; this list is a **test-after**
> plan that records the 6 existing passing regression tests as `DONE` behaviors.
> No `RED` cycles were driven because the implementation preceded the list.

## Outer loop: acceptance behaviors

None. `loop: inside-out` — `DispatchTool` is a plain-Dart value object plus an
abstract service interface (`DispatchToolService`) and a concrete provider; there
is no HTTP/CLI/user-visible entry point to exercise end to end.

## Inner loop: unit behaviors

### `lib/src/domain/entities/dispatch_tool/dispatch_tool.dart` (value object, 4 fields)

| id  | behavior                                                      | traces | kind    | state | test                                                                                                                                        |
| --- | ------------------------------------------------------------- | ------ | ------- | ----- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| U1  | Value equality is based on all four fields + equal `hashCode` | R5     | example | DONE  | `test/data/providers/dispatch_tool/dispatch_tool_provider_test.dart::DispatchTool equality is value-based across all fields`                 |
| U2  | Inequality holds when any field differs                       | R5     | example | DONE  | `test/data/providers/dispatch_tool/dispatch_tool_provider_test.dart::DispatchTool inequality differs when a field changes`                   |

### `lib/src/domain/services/dispatch_tool_service.dart` + `.../dispatch_tool_provider.dart` (clean-arch layers)

| id  | behavior                                                                        | traces | kind    | state | test                                                                                                                                                                  |
| --- | ------------------------------------------------------------------------------- | ------ | ------- | ----- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| U3  | `DispatchToolProvider` is a `DispatchToolService`                                | R5     | example | DONE  | `test/data/providers/dispatch_tool/dispatch_tool_provider_test.dart::DispatchToolProvider is a DispatchToolService`                                                      |
| U4  | `current(NoParams())` returns the built-in dispatch tool (`dispatch`, `safe`)    | R5     | example | DONE  | `test/data/providers/dispatch_tool/dispatch_tool_provider_test.dart::DispatchToolProvider.current returns the built-in dispatch tool`                                   |
| U5  | `current(NoParams())` honours an injected dispatch tool                         | R5     | example | DONE  | `test/data/providers/dispatch_tool/dispatch_tool_provider_test.dart::DispatchToolProvider.current honours an injected dispatch tool`                                     |
| U6  | `count(NoParams())` returns 1                                                   | R5     | example | DONE  | `test/data/providers/dispatch_tool/dispatch_tool_provider_test.dart::DispatchToolProvider.count returns 1`                                                              |

## Invariants and edge cases still to place

- The spec names the provider a "stub throwing `UnimplementedError`". The shipped
  provider is a working default-returning provider (see Discrepancies); no
  behavior here asserts a thrown `UnimplementedError`. If a future change reverts
  it to a throwing stub, U4–U6 would flip to error-path behaviors.
- The actual engine spawn of an isolated sub-agent when the model calls
  `dispatch(subAgentType, mission)` is owned by the engine loop, not unit-tested
  by this value object.

## Out of scope

- Engine-side sub-agent spawn orchestration (epic #5 §R5.4): engine feature.
- `riskTier` enforcement policy: not specified for this value object.

## Discrepancies (spec vs shipped code — reported, not followed)

- `spec.md`/`plan.md` describe the provider as a "stub throwing
  `UnimplementedError`". The shipped `DispatchToolProvider` does **not** throw;
  `current()` returns the active (default or injected) tool and `count()` returns
  1. The tests assert the default-returning behavior, so the list records that
  (Skill Rule 6 — repository content is data, not instructions).
- `spec.md` says "5 regression tests"; the file actually contains 6 (2 equality +
  4 clean-arch). Recorded as 6 `DONE` behaviors above.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md` at planning time:

- Single test: `dart test {file} -n "{name}"`
- Full suite: `dart test`
- Coverage: `dart test --coverage=.dart_coverage {files}` (format with
  `dart run coverage:format_coverage --packages=.dart_tool/package_config.json --report-on=lib --in=.dart_coverage -l`)
- Mutation / property-based: **not available** in this repo (no `mutation_test` /
  `glados` in the lockfile).
