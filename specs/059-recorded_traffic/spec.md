# Feature Specification: RecordedTraffic (LLM + tool capture)

**Branch**: `059-recorded_traffic` | **Date**: 2026-08-24

## Summary
LLM + tool traffic recording — every LLM call and tool dispatch captured as a typed entry (epic #6 §R6.1, issue #7 US1). The replay source-of-truth. This advances epic issue #7 (Eval Harness). Pattern: hand-curated plain Dart value object (no @Zorphy), abstract service interface with NoParams parameters, concrete provider stub throwing UnimplementedError, regression tests for value equality + clean-arch layering.

## Files
- `lib/src/domain/entities/recorded_traffic/recorded_traffic.dart` - `RecordedTraffic` value object (5 fields; value-based equality).
- `lib/src/domain/services/recorded_traffic_service.dart` - abstract `RecordedTrafficService` (current(NoParams), count(NoParams)).
- `lib/src/data/providers/recorded_traffic/recorded_traffic_provider.dart` - concrete `RecordedTrafficProvider` stub (UnimplementedError bodies).
- `test/data/providers/recorded_traffic/recorded_traffic_provider_test.dart` - 5 regression tests (2 entity equality + 3 clean-arch).
- `specs/059-recorded_traffic/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` - No issues
- `dart test` - All pre-existing + 5 new tests pass

## Advances #7 (Eval Harness)
