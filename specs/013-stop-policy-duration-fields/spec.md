# Feature Specification: StopPolicy Duration field support

**Branch**: `013-stop-policy-duration-fields` | **Date**: 2026-08-24

## Summary
Extend the hand-curated `StopPolicy` value object (added in PR #45 for #27/#28) to ship the spec-exact surface from `specs/002-engine-core-loop/data-model.md`: `maxTurns:int, wallClockTimeout:Duration, repetitionThreshold:int, enabled:bool`. Issue #13 surfaces the zfa v6.0.0 bug where `zfa entity create -n StopPolicy --fields "...wallClockTimeout:Duration..."` rejects Duration as a field type. The hand-curated entity demonstrates that the spec-exact StopPolicy (with Duration) lives in the repo, ahead of zfa's upstream fix.

## Files
- `lib/src/domain/entities/stop_policy/stop_policy.dart` — extended with `maxTurns`, `wallClockTimeout: Duration`, `repetitionThreshold`, `enabled` fields.
- `test/data/datasources/stop_policy/stop_policy_mock_datasource_test.dart` — extended with 5 new tests (#13 regression block).
- `specs/013-stop-policy-duration-fields/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — All pre-existing + 5 new tests pass

## Closes #13
