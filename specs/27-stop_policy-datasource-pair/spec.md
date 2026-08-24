# Feature Specification: StopPolicy datasource + mock pair

**Branch**: `27-stop_policy-datasource-pair` | **Date**: 2026-08-24

## Summary
Hand-curated `<slug>_datasource.dart` (abstract interface) and `<slug>_mock_datasource.dart` (concrete stub) for the `StopPolicy` value object. Closes the two sibling issues #`27` (uri_does_not_exist) and #`28` (implements_non_class). zfa's value-object mode emits the mock_datasource that imports + implements the interface, but skips emitting the interface file itself — a self-contradictory codegen bug. This PR ships both files in the consuming repo.

## Files
- `lib/src/domain/entities/stop_policy/stop_policy.dart` — Zorphy value-object entity (hand-curated to back the datasource surface)
- `lib/src/data/datasources/stop_policy/stop_policy_datasource.dart` — abstract `StopPolicyDatasource` interface
- `lib/src/data/datasources/stop_policy/stop_policy_mock_datasource.dart` — concrete `StopPolicyMockDatasource` stub
- `test/data/datasources/stop_policy/stop_policy_mock_datasource_test.dart` — 3 regression tests
- `specs/27-stop_policy-datasource-pair/{spec,plan,tasks}.md`

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — All pre-existing + 3 new tests pass

## Closes #27, closes #28
