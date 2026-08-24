# Feature Specification: RepetitionTracker datasource + mock pair

**Branch**: `25-repetition_tracker-datasource-pair` | **Date**: 2026-08-24

## Summary
Hand-curated `<slug>_datasource.dart` (abstract interface) and `<slug>_mock_datasource.dart` (concrete stub) for the `RepetitionTracker` value object. Closes the two sibling issues #`25` (uri_does_not_exist) and #`26` (implements_non_class). zfa's value-object mode emits the mock_datasource that imports + implements the interface, but skips emitting the interface file itself — a self-contradictory codegen bug. This PR ships both files in the consuming repo.

## Files
- `lib/src/domain/entities/repetition_tracker/repetition_tracker.dart` — Zorphy value-object entity (hand-curated to back the datasource surface)
- `lib/src/data/datasources/repetition_tracker/repetition_tracker_datasource.dart` — abstract `RepetitionTrackerDatasource` interface
- `lib/src/data/datasources/repetition_tracker/repetition_tracker_mock_datasource.dart` — concrete `RepetitionTrackerMockDatasource` stub
- `test/data/datasources/repetition_tracker/repetition_tracker_mock_datasource_test.dart` — 3 regression tests
- `specs/25-repetition_tracker-datasource-pair/{spec,plan,tasks}.md`

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — All pre-existing + 3 new tests pass

## Closes #25, closes #26
