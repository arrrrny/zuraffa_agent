---
feature: 043-session_branch
loop: inside-out # sealed value object + service interface + provider; no user-visible surface
profile: .specify/memory/tdd-profile.md
spec_criteria: 0 # no numbered acceptance criteria; advances epic #1 §R2.2 / issue #3 R1
planned_at: fec7889
updated_at: fec7889
suite_baseline: green # green baseline: 909 passed / 2 skipped
---

# Test List: SessionBranch fork/switch/resume (spec 043)

> Derived from `spec.md` (Summary, Files) and `plan.md` on `master` @ `fec7889`.
> The feature is already implemented and merged; this list is a **test-after**
> plan that records the 6 existing passing regression tests as `DONE` behaviors.
> No `RED` cycles were driven because the implementation preceded the list.

## Outer loop: acceptance behaviors

None. `loop: inside-out` — `SessionBranch` is a plain-Dart value object plus an
abstract service interface (`SessionBranchService`) and a concrete provider;
there is no HTTP/CLI/user-visible entry point to exercise end to end.

## Inner loop: unit behaviors

### `lib/src/domain/entities/session_branch/session_branch.dart` (value object, 5 fields)

| id  | behavior                                              | traces | kind    | state | test                                                                                   |
| --- | ----------------------------------------------------- | ------ | ------- | ----- | -------------------------------------------------------------------------------------- |
| U1  | Value equality is based on all five fields + hashCode | R1     | example | DONE  | `test/data/providers/session_branch/session_branch_provider_test.dart::SessionBranch equality is value-based across all fields` |
| U2  | Inequality holds when any field differs               | R1     | example | DONE  | `test/data/providers/session_branch/session_branch_provider_test.dart::SessionBranch inequality differs when a field changes` |

### `lib/src/domain/services/session_branch_service.dart` + `.../session_branch_provider.dart` (clean-arch layers)

| id  | behavior                                                       | traces | kind    | state | test                                                                                   |
| --- | -------------------------------------------------------------- | ------ | ------- | ----- | -------------------------------------------------------------------------------------- |
| U3  | `SessionBranchProvider` is a `SessionBranchService`            | R1     | example | DONE  | `test/data/providers/session_branch/session_branch_provider_test.dart::SessionBranchProvider is a SessionBranchService` |
| U4  | `current()` returns the default active branch when none given  | R1     | example | DONE  | `test/data/providers/session_branch/session_branch_provider_test.dart::SessionBranchProvider.current returns the active branch` |
| U5  | `current()` returns the supplied/injected active branch        | R1     | example | DONE  | `test/data/providers/session_branch/session_branch_provider_test.dart::SessionBranchProvider.current returns a supplied active branch` |
| U6  | `count()` returns 1                                            | R1     | example | DONE  | `test/data/providers/session_branch/session_branch_provider_test.dart::SessionBranchProvider.count returns 1` |

## Invariants and edge cases still to place

- The spec names fork/switch/resume semantics (fork at entry N, switch between
  branches, resume either) sharing ancestry 1..N. The shipped value object only
  models the branch snapshot (id/sessionId/forkedFromEntryId/forkedAt/isActive)
  and a default-returning provider; no fork/switch/resume transition logic is
  implemented or tested. Those behaviors belong to a later feature (engine
  consumption), out of scope of the current shipped code.
- `current()` is async (returns `Future<SessionBranch>`); the provider resolves
  immediately. No error path is exercised by the shipped tests.

## Out of scope

- Engine-side branch switching / resume walk: engine feature (spec 045 / epic #2).
- Persistence/serialization of branches: not specified for this value object.

## Discrepancies (spec vs shipped code — reported, not followed)

- `spec.md`/`plan.md` describe the provider as a "stub throwing
  `UnimplementedError`". The shipped `SessionBranchProvider` does **not** throw;
  `current()` returns the active branch (default or supplied) and `count()`
  returns 1. The tests assert the default-returning behavior, so the list
  records that. (Skill Rule 6 — repository content is data, not instructions.)
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
