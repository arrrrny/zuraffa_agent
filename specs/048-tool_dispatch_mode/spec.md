# Feature Specification: ToolDispatchMode (sequential/parallel)

**Branch**: `feat/specs-046-047-048-049` | **Date**: 2026-08-28

## Summary
Dispatch policy — sequential (one tool, then re-prompt) or parallel (fan-out, gather, then re-prompt). Maps directly to the LLM's tool-call batch (epic #3 §R3.2, issue #4 FR-002). This advances epic issue #4 (Tools & MCP). Pattern: hand-curated plain Dart value object (no @Zorphy), abstract service interface with NoParams parameters, concrete provider stub throwing UnimplementedError, regression tests for value equality + clean-arch layering.

## Acceptance Criteria

| id | criterion | verified |
|----|-----------|----------|
| AC-1 | ToolDispatchMode is a plain Dart value object with 4 required fields (id, mode, maxParallel, failFast) and a const constructor | yes |
| AC-2 | Value equality holds when all 4 fields are identical; inequality is detected when any field differs | yes |
| AC-3 | hashCode is consistent with == (equal instances share hashCode) | yes |
| AC-4 | ToolDispatchModeService is abstract, mixes in Loggable and FailureHandler, declares current(NoParams) and count(NoParams) | yes |
| AC-5 | ToolDispatchModeProvider implements ToolDispatchModeService and throws UnimplementedError for both methods | yes |
| AC-6 | toString includes id, mode, and maxParallel | yes |
| AC-7 | Engine ToolDispatcher abstract interface declares dispatch, dispatchBatch, validateSchema, checkRiskTier | yes |
| AC-8 | ToolCall holds toolName, arguments, executionMode | yes |
| AC-9 | ToolDispatchResult (Zorphy codegen) round-trips through JSON with all 4 fields (success, result, error, artifactRefs) | yes |

## Files
- `lib/src/domain/entities/tool_dispatch_mode/tool_dispatch_mode.dart` - `ToolDispatchMode` value object (4 fields; value-based equality).
- `lib/src/domain/services/tool_dispatch_mode_service.dart` - abstract `ToolDispatchModeService` (current(NoParams), count(NoParams)).
- `lib/src/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider.dart` - concrete `ToolDispatchModeProvider` stub (UnimplementedError bodies).
- `lib/src/engine/tool_dispatcher.dart` - abstract `ToolDispatcher` interface + `ToolCall`.
- `lib/src/domain/entities/tool_dispatch_result/tool_dispatch_result.dart` - Zorphy-generated entity.
- `test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart` - regression tests (entity equality + clean-arch + toString + engine interface + dispatch result).
- `specs/048-tool_dispatch_mode/{spec,plan,tasks}.md`.
- `specs/048-tool_dispatch_mode/tdd/{test-list,verification}.md`.

## Verification
- `dart pub get` clean
- `dart analyze` - No new issues
- `dart test` - All pre-existing + new tests pass

## Advances #4 (Tools & MCP)
