**Template Version**: `zuraffa-1.0`

# Feature Specification: ToolDispatchMode (sequential/parallel)

**Branch**: `feat/specs-046-047-048-049` | **Date**: 2026-08-28

## Summary
Dispatch policy — sequential (one tool, then re-prompt) or parallel (fan-out, gather, then re-prompt). Maps directly to the LLM's tool-call batch (epic #3 §R3.2, issue #4 FR-002). This advances epic issue #4 (Tools & MCP). Pattern: hand-curated plain Dart value object (no @Zorphy), abstract service interface with NoParams parameters, concrete provider stub throwing UnimplementedError, regression tests for value equality + clean-arch layering.

## Acceptance Criteria

| id | criterion | verified |
|----|-----------|----------|
1. **Given** the implemented feature **When** its acceptance criterion applies — | ToolDispatchMode is a plain Dart value object with 4 required fields (id, mode, maxParallel, failFast) and a const constructor | yes | — **Then** the pinned regression suite confirms it.
   **Type**: acceptance
2. **Given** the implemented feature **When** its acceptance criterion applies — | Value equality holds when all 4 fields are identical; inequality is detected when any field differs | yes | — **Then** the pinned regression suite confirms it.
   **Type**: acceptance
3. **Given** the implemented feature **When** its acceptance criterion applies — | hashCode is consistent with == (equal instances share hashCode) | yes | — **Then** the pinned regression suite confirms it.
   **Type**: acceptance
4. **Given** the implemented feature **When** its acceptance criterion applies — | ToolDispatchModeService is abstract, mixes in Loggable and FailureHandler, declares current(NoParams) and count(NoParams) | yes | — **Then** the pinned regression suite confirms it.
   **Type**: acceptance
5. **Given** the implemented feature **When** its acceptance criterion applies — | ToolDispatchModeProvider implements ToolDispatchModeService and throws UnimplementedError for both methods | yes | — **Then** the pinned regression suite confirms it.
   **Type**: acceptance
6. **Given** the implemented feature **When** its acceptance criterion applies — | toString includes id, mode, and maxParallel | yes | — **Then** the pinned regression suite confirms it.
   **Type**: acceptance
7. **Given** the implemented feature **When** its acceptance criterion applies — | Engine ToolDispatcher abstract interface declares dispatch, dispatchBatch, validateSchema, checkRiskTier | yes | — **Then** the pinned regression suite confirms it.
   **Type**: acceptance
8. **Given** the implemented feature **When** its acceptance criterion applies — | ToolCall holds toolName, arguments, executionMode | yes | — **Then** the pinned regression suite confirms it.
   **Type**: acceptance
9. **Given** the implemented feature **When** its acceptance criterion applies — | ToolDispatchResult (Zorphy codegen) round-trips through JSON with all 4 fields (success, result, error, artifactRefs) | yes | — **Then** the pinned regression suite confirms it.
   **Type**: acceptance

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

## Acceptance Scenarios

> Derived verbatim from the feature's pinned regression suite.
> Behaviors are inherited-green: the cited tests pass unmodified in
> the repo suite (dart test, 1201 passing).
10. **Given** the feature implementation under its clean-architecture seams **When** ToolDispatchMode equality is value-based across all fields **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`).
   **Type**: acceptance
11. **Given** the feature implementation under its clean-architecture seams **When** ToolDispatchMode inequality differs when a field changes **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`).
   **Type**: acceptance
12. **Given** the feature implementation under its clean-architecture seams **When** ToolDispatchMode inequality detected per-field: id **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`).
   **Type**: acceptance
13. **Given** the feature implementation under its clean-architecture seams **When** ToolDispatchMode inequality detected per-field: mode **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`).
   **Type**: acceptance
14. **Given** the feature implementation under its clean-architecture seams **When** ToolDispatchMode inequality detected per-field: maxParallel **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`).
   **Type**: acceptance
15. **Given** the feature implementation under its clean-architecture seams **When** ToolDispatchMode inequality detected per-field: failFast **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`).
   **Type**: acceptance
16. **Given** the feature implementation under its clean-architecture seams **When** toString includes id, mode, and maxParallel **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`).
   **Type**: acceptance
17. **Given** the feature implementation under its clean-architecture seams **When** ToolDispatchModeProvider is a ToolDispatchModeService **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`).
   **Type**: acceptance
18. **Given** the feature implementation under its clean-architecture seams **When** ToolDispatchModeProvider.current returns the active dispatch mode **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`).
   **Type**: acceptance
19. **Given** the feature implementation under its clean-architecture seams **When** ToolDispatchModeProvider.count returns 1 **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`).
   **Type**: acceptance
20. **Given** the feature implementation under its clean-architecture seams **When** ToolCall holds toolName, arguments, executionMode **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`).
   **Type**: acceptance
21. **Given** the feature implementation under its clean-architecture seams **When** ToolCall const constructor **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`).
   **Type**: acceptance
22. **Given** the feature implementation under its clean-architecture seams **When** ToolDispatchResult round-trips through JSON with all 4 fields **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`).
   **Type**: acceptance
23. **Given** the feature implementation under its clean-architecture seams **When** ToolDispatchResult error round-trip **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`).
   **Type**: acceptance
24. **Given** the feature implementation under its clean-architecture seams **When** ToolDispatchResult.copyWith produces new instance **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`).
   **Type**: acceptance
25. **Given** the feature implementation under its clean-architecture seams **When** ToolDispatchResult hasResult / noResult helpers **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`).
   **Type**: acceptance
26. **Given** the feature implementation under its clean-architecture seams **When** ToolDispatchResult hasError / noError helpers **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`).
   **Type**: acceptance
27. **Given** the feature implementation under its clean-architecture seams **When** ToolDispatchResult JSON encoding produces all keys **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`).
   **Type**: acceptance
