# Feature Specification: DartIoFreeGate (static gate)

**Branch**: `064-dart_io_free_gate` | **Date**: 2026-08-24

## Summary
Static gate that fails the build if the eval runtime imports the platform IO module (epic #6 §R6.5, issue #7 US5). Keeps the eval harness consumable from web platforms. This advances epic issue #7 (Eval Harness). Pattern: hand-curated plain Dart value object (no @Zorphy), abstract service interface with NoParams parameters, concrete provider stub throwing UnimplementedError, regression tests for value equality + clean-arch layering.

## Files
- `lib/src/domain/entities/dart_io_free_gate/dart_io_free_gate.dart` - `DartIoFreeGate` value object (4 fields; value-based equality).
- `lib/src/domain/services/dart_io_free_gate_service.dart` - abstract `DartIoFreeGateService` (current(NoParams), count(NoParams)).
- `lib/src/data/providers/dart_io_free_gate/dart_io_free_gate_provider.dart` - concrete `DartIoFreeGateProvider` stub (UnimplementedError bodies).
- `test/data/providers/dart_io_free_gate/dart_io_free_gate_provider_test.dart` - 5 regression tests (2 entity equality + 3 clean-arch).
- `specs/064-dart_io_free_gate/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` - No issues
- `dart test` - All pre-existing + 5 new tests pass

## Advances #7 (Eval Harness)
