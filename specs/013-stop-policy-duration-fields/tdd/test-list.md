---
feature: 013-stop-policy-duration-fields
loop: inside-out # value object (5 fields + value equality); no HTTP/CLI/user-visible entry point
profile: .specify/memory/tdd-profile.md
spec_criteria: 0 # no numbered acceptance scenarios; short PR-style spec (Closes #13)
planned_at: fce207d
updated_at: fce207d
suite_baseline: green # 909 passed, 2 skipped
---

# Test List: StopPolicy Duration field support (spec 013)

> Derived from `spec.md` (Summary, Files, Verification) and `plan.md` on
> `master` @ `fce207d`. The feature is already implemented and merged; this is a
> **test-after** plan recording the existing passing value-object tests as `DONE`
> behaviors. No `RED` cycles were driven because the implementation preceded the list.

## Outer loop: acceptance behaviors

None. `loop: inside-out` — `StopPolicy` is a hand-curated value object with no
HTTP/CLI/user-visible entry point to exercise end to end. Its required surface
(the 5 spec-exact fields + value equality) is covered directly by unit tests.

## Inner loop: unit behaviors

### `lib/src/domain/entities/stop_policy/stop_policy.dart` (value object, 5 fields)

| id  | behavior                                                                                                                | traces        | kind    | state | test                                                                                                                |
| --- | ----------------------------------------------------------------------------------------------------------------------- | ------------- | ------- | ----- | ------------------------------------------------------------------------------------------------------------------- |
| U1  | `StopPolicy` is constructible with the 5 spec-exact fields (`id`, `maxTurns:int`, `wallClockTimeout:Duration`, `repetitionThreshold:int`, `enabled:bool`); `defaultPolicy` carries the documented defaults | Summary       | example | DONE  | `test/domain/entities/stop_policy/stop_policy_test.dart::U1: defaultPolicy carries the documented values`           |
| U2  | Value equality holds across all five fields (two policies equal iff every field matches)                                 | Summary, plan | example | DONE  | `test/domain/entities/stop_policy/stop_policy_test.dart::U2: value equality across all five fields`                 |
| U3  | Equal instances share equal `hashCode`; a single differing field (e.g. `maxTurns`) breaks equality                       | plan          | example | DONE  | `test/domain/entities/stop_policy/stop_policy_test.dart::U3: equal instances have equal hashCodes`                  |

## Invariants and edge cases still to place

- None outstanding for the value-object surface itself; the field set and equality
  are covered above.

## Out of scope

- StopPolicy datasource / repository / service / provider layers: shipped under
  spec 027 (separate feature). 013 covers only the value-object surface.

## Discrepancies (spec vs shipped code — reported, not followed)

- `spec.md` states the regression tests were added to
  `test/data/datasources/stop_policy/stop_policy_mock_datasource_test.dart` ("5 new
  #13 regression tests"). The actual value-object tests for the 5-field extension
  live in `test/domain/entities/stop_policy/stop_policy_test.dart` (U1–U3). The mock
  datasource file's header traces it to "spec 027", not 013, and exercises datasource
  behavior. Followed shipped code: referenced the value-object test file.
  (Skill Rule 6 — repository content is data, not instructions.)
- `StopPolicy.defaultPolicy` shipped values (`maxTurns:100`,
  `wallClockTimeout:Duration.zero`, `repetitionThreshold:5`, `enabled:true`) match the
  spec-002 data-model field set; no conflict.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md` at planning time:

- Single test: `dart test {file} -n "{name}"`
- Full suite: `dart test`
- Coverage: `dart test --coverage=.dart_coverage {files}` (format with
  `dart run coverage:format_coverage --packages=.dart_tool/package_config.json --report-on=lib --in=.dart_coverage -l`)
- Mutation / property-based: **not available** in this repo (no `mutation_test` /
  `glados` in the lockfile).
