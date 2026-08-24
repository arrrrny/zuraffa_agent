# Feature Specification: EngineLoop (while-loop executor)

**Branch**: `045-engine_loop` | **Date**: 2026-08-24

## Summary
The turn-based while-loop executor advancing on LLM finish-reason (epic #2 §R1.1, issue #2). No FSM — the model drives; the loop dispatches tool calls, feeds results back, drains the steering queue between turns, emits typed events. This advances epic issue #2 (Engine Core Loop). Pattern: hand-curated plain Dart value object (no @Zorphy), abstract service interface with NoParams parameters, concrete provider stub throwing UnimplementedError, regression tests for value equality + clean-arch layering.

## Files
- `lib/src/domain/entities/engine_loop/engine_loop.dart` - `EngineLoop` value object (5 fields; value-based equality).
- `lib/src/domain/services/engine_loop_service.dart` - abstract `EngineLoopService` (current(NoParams), count(NoParams)).
- `lib/src/data/providers/engine_loop/engine_loop_provider.dart` - concrete `EngineLoopProvider` stub (UnimplementedError bodies).
- `test/data/providers/engine_loop/engine_loop_provider_test.dart` - 5 regression tests (2 entity equality + 3 clean-arch).
- `specs/045-engine_loop/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` - No issues
- `dart test` - All pre-existing + 5 new tests pass

## Advances #2 (Engine Core Loop)
