---
feature: 042-session_tree_entry
loop: inside-out # sealed value object + service interface; no user-visible surface
profile: .specify/memory/tdd-profile.md
spec_criteria: 0 # no numbered acceptance criteria; advances epic #3 (State & Sessions) §R2.1
planned_at: 30b4b94
updated_at: 30b4b94
suite_baseline: green # 911 passed, dart analyze clean
---

# Test List: SessionTreeEntry sealed hierarchy (spec 042)

> Derived from `spec.md` (Summary, Files) and `plan.md` on `master` @ `30b4b94`.
> The feature is already implemented and merged; this list is a **test-after**
> plan that records the 6 existing passing regression tests as `DONE` behaviors.
> No `RED` cycles were driven because the implementation preceded the list.

## Outer loop: acceptance behaviors

None. `loop: inside-out` — `SessionTreeEntry` is a sealed plain-Dart value object
plus an abstract service interface (`SessionTreeEntryService`) and a default
provider; there is no HTTP/CLI/user-visible entry point to exercise end to end.

## Inner loop: unit behaviors

### `lib/src/domain/entities/session_tree_entry/session_tree_entry.dart` (value object, 4 fields)

| id  | behavior                                              | traces | kind     | state | test                                                                                        |
| --- | ----------------------------------------------------- | ------ | ------- | ----- | ------------------------------------------------------------------------------------------- |
| U1  | Value equality is based on all four fields + hashCode | R1     | example | DONE  | `test/data/providers/session_tree_entry/session_tree_entry_provider_test.dart::SessionTreeEntry equality is value-based across all fields` |
| U2  | Inequality holds when any field differs               | R1     | example | DONE  | `test/data/providers/session_tree_entry/session_tree_entry_provider_test.dart::SessionTreeEntry inequality differs when a field changes` |

### `lib/src/domain/services/session_tree_entry_service.dart` + `.../session_tree_entry_provider.dart` (clean-arch layers)

| id  | behavior                                                       | traces | kind     | state | test                                                                                        |
| --- | -------------------------------------------------------------- | ------ | ------- | ----- | ------------------------------------------------------------------------------------------- |
| U3  | `SessionTreeEntryProvider` is a `SessionTreeEntryService`      | R1     | example | DONE  | `test/data/providers/session_tree_entry/session_tree_entry_provider_test.dart::SessionTreeEntryProvider is a SessionTreeEntryService` |
| U4  | `current()` returns a default active entry when none supplied  | R1     | example | DONE  | `test/data/providers/session_tree_entry/session_tree_entry_provider_test.dart::SessionTreeEntryProvider.current returns the active entry` |
| U5  | `current()` returns the supplied/injected active entry         | R1     | example | DONE  | `test/data/providers/session_tree_entry/session_tree_entry_provider_test.dart::SessionTreeEntryProvider.current returns a supplied active entry` |
| U6  | `count()` returns 1                                            | R1     | example | DONE  | `test/data/providers/session_tree_entry/session_tree_entry_provider_test.dart::SessionTreeEntryProvider.count returns 1` |

## Invariants and edge cases still to place

- The spec names a sealed union of entry subtypes (message / thinking-level-change
  / model-change / compaction / label / custom) "unified" by `SessionTreeEntry`.
  The shipped value object is a single 4-field class; no subtype tests exist. If a
  sealed hierarchy is intended, that belongs on a later behavior (out of scope of
  the current shipped code).
- "Dispatch by type gives the engine one entry-list walk per turn" is an
  integration concern owned by the engine loop, not unit-tested here.

## Out of scope

- Engine-side consumption of the entry list (epic #1 §R2.1 walk): engine feature.
- Persistence/serialization of entries: not specified for this value object.

## Discrepancies (spec vs shipped code — reported, not followed)

- `spec.md`/`plan.md` describe the provider as a "stub throwing `UnimplementedError`".
  The shipped `SessionTreeEntryProvider` does **not** throw; `current()` returns a
  default entry and `count()` returns 1. The tests assert the default-returning
  behavior, so the list records that. (Skill Rule 6 — repository content is data,
  not instructions.)
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
