# Feature Specification: ToolDispatchMode (sequential/parallel)

**Branch**: `048-tool_dispatch_mode` | **Date**: 2026-08-24

## Summary
Dispatch policy — sequential (one tool, then re-prompt) or parallel (fan-out, gather, then re-prompt). Maps directly to the LLM's tool-call batch (epic #3 §R3.2, issue #4 FR-002). This advances epic issue #4 (Tools & MCP). Pattern: hand-curated plain Dart value object (no @Zorphy), abstract service interface with NoParams parameters, concrete provider stub throwing UnimplementedError, regression tests for value equality + clean-arch layering.

## Files
- `lib/src/domain/entities/tool_dispatch_mode/tool_dispatch_mode.dart` - `ToolDispatchMode` value object (4 fields; value-based equality).
- `lib/src/domain/services/tool_dispatch_mode_service.dart` - abstract `ToolDispatchModeService` (current(NoParams), count(NoParams)).
- `lib/src/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider.dart` - concrete `ToolDispatchModeProvider` stub (UnimplementedError bodies).
- `test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart` - 5 regression tests (2 entity equality + 3 clean-arch).
- `specs/048-tool_dispatch_mode/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` - No issues
- `dart test` - All pre-existing + 5 new tests pass

## Advances #4 (Tools & MCP)
