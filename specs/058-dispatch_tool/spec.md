**Template Version**: `zuraffa-1.0`

# Feature Specification: DispatchTool (built-in)

**Branch**: `058-dispatch_tool` | **Date**: 2026-08-24

## Summary
Built-in dispatch tool — the model calls dispatch(subAgentType='X', mission='…') and the engine spawns an isolated sub-agent (epic #5 §R5.4, issue #6 US4). This advances epic issue #6 (Sub-agents & Declarative). Pattern: hand-curated plain Dart value object (no @Zorphy), abstract service interface with NoParams parameters, concrete provider stub throwing UnimplementedError, regression tests for value equality + clean-arch layering.

## Files
- `lib/src/domain/entities/dispatch_tool/dispatch_tool.dart` - `DispatchTool` value object (4 fields; value-based equality).
- `lib/src/domain/services/dispatch_tool_service.dart` - abstract `DispatchToolService` (current(NoParams), count(NoParams)).
- `lib/src/data/providers/dispatch_tool/dispatch_tool_provider.dart` - concrete `DispatchToolProvider` stub (UnimplementedError bodies).
- `test/data/providers/dispatch_tool/dispatch_tool_provider_test.dart` - 5 regression tests (2 entity equality + 3 clean-arch).
- `specs/058-dispatch_tool/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` - No issues
- `dart test` - All pre-existing + 5 new tests pass

## Advances #6 (Sub-agents & Declarative)

## Acceptance Scenarios

> Derived verbatim from the feature's pinned regression suite.
> Behaviors are inherited-green: the cited tests pass unmodified in
> the repo suite (dart test, 1201 passing).
1. **Given** the feature implementation under its clean-architecture seams **When** DispatchTool equality is value-based across all fields **Then** the pinned regression test passes (`test/data/providers/dispatch_tool/dispatch_tool_provider_test.dart`).
   **Type**: acceptance
2. **Given** the feature implementation under its clean-architecture seams **When** DispatchTool inequality differs when a field changes **Then** the pinned regression test passes (`test/data/providers/dispatch_tool/dispatch_tool_provider_test.dart`).
   **Type**: acceptance
3. **Given** the feature implementation under its clean-architecture seams **When** DispatchToolProvider is a DispatchToolService **Then** the pinned regression test passes (`test/data/providers/dispatch_tool/dispatch_tool_provider_test.dart`).
   **Type**: acceptance
4. **Given** the feature implementation under its clean-architecture seams **When** DispatchToolProvider.current returns the built-in dispatch tool **Then** the pinned regression test passes (`test/data/providers/dispatch_tool/dispatch_tool_provider_test.dart`).
   **Type**: acceptance
5. **Given** the feature implementation under its clean-architecture seams **When** DispatchToolProvider.current honours an injected dispatch tool **Then** the pinned regression test passes (`test/data/providers/dispatch_tool/dispatch_tool_provider_test.dart`).
   **Type**: acceptance
6. **Given** the feature implementation under its clean-architecture seams **When** DispatchToolProvider.count returns 1 **Then** the pinned regression test passes (`test/data/providers/dispatch_tool/dispatch_tool_provider_test.dart`).
   **Type**: acceptance
