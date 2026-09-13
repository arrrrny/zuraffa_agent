# Traceability: 048-tool_dispatch_mode

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:7c73437e8666c3311aa442f7e3dd05e3567fb3ed25672e817ddc787789f9a2b2
statements: 27
automated: 27
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 14 | 1. **Given** the implemented feature **When** its acceptance criterion applies — \| ToolDispatchMode is a plain Dart value object with 4 required fields (id, mode, maxParallel, failFast) and a const constructor \| yes \| — **Then** the pinned regression suite confirms it. | A1 | automated |
| AC-2 | 15 | 2. **Given** the implemented feature **When** its acceptance criterion applies — \| Value equality holds when all 4 fields are identical; inequality is detected when any field differs \| yes \| — **Then** the pinned regression suite confirms it. | A2 | automated |
| AC-3 | 16 | 3. **Given** the implemented feature **When** its acceptance criterion applies — \| hashCode is consistent with == (equal instances share hashCode) \| yes \| — **Then** the pinned regression suite confirms it. | A3 | automated |
| AC-4 | 17 | 4. **Given** the implemented feature **When** its acceptance criterion applies — \| ToolDispatchModeService is abstract, mixes in Loggable and FailureHandler, declares current(NoParams) and count(NoParams) \| yes \| — **Then** the pinned regression suite confirms it. | A4 | automated |
| AC-5 | 18 | 5. **Given** the implemented feature **When** its acceptance criterion applies — \| ToolDispatchModeProvider implements ToolDispatchModeService and throws UnimplementedError for both methods \| yes \| — **Then** the pinned regression suite confirms it. | A5 | automated |
| AC-6 | 19 | 6. **Given** the implemented feature **When** its acceptance criterion applies — \| toString includes id, mode, and maxParallel \| yes \| — **Then** the pinned regression suite confirms it. | A6 | automated |
| AC-7 | 20 | 7. **Given** the implemented feature **When** its acceptance criterion applies — \| Engine ToolDispatcher abstract interface declares dispatch, dispatchBatch, validateSchema, checkRiskTier \| yes \| — **Then** the pinned regression suite confirms it. | A7 | automated |
| AC-8 | 21 | 8. **Given** the implemented feature **When** its acceptance criterion applies — \| ToolCall holds toolName, arguments, executionMode \| yes \| — **Then** the pinned regression suite confirms it. | A8 | automated |
| AC-9 | 22 | 9. **Given** the implemented feature **When** its acceptance criterion applies — \| ToolDispatchResult (Zorphy codegen) round-trips through JSON with all 4 fields (success, result, error, artifactRefs) \| yes \| — **Then** the pinned regression suite confirms it. | A9 | automated |
| AC-10 | 46 | 10. **Given** the feature implementation under its clean-architecture seams **When** ToolDispatchMode equality is value-based across all fields **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`). | A10 | automated |
| AC-11 | 47 | 11. **Given** the feature implementation under its clean-architecture seams **When** ToolDispatchMode inequality differs when a field changes **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`). | A11 | automated |
| AC-12 | 48 | 12. **Given** the feature implementation under its clean-architecture seams **When** ToolDispatchMode inequality detected per-field: id **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`). | A12 | automated |
| AC-13 | 49 | 13. **Given** the feature implementation under its clean-architecture seams **When** ToolDispatchMode inequality detected per-field: mode **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`). | A13 | automated |
| AC-14 | 50 | 14. **Given** the feature implementation under its clean-architecture seams **When** ToolDispatchMode inequality detected per-field: maxParallel **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`). | A14 | automated |
| AC-15 | 51 | 15. **Given** the feature implementation under its clean-architecture seams **When** ToolDispatchMode inequality detected per-field: failFast **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`). | A15 | automated |
| AC-16 | 52 | 16. **Given** the feature implementation under its clean-architecture seams **When** toString includes id, mode, and maxParallel **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`). | A16 | automated |
| AC-17 | 53 | 17. **Given** the feature implementation under its clean-architecture seams **When** ToolDispatchModeProvider is a ToolDispatchModeService **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`). | A17 | automated |
| AC-18 | 54 | 18. **Given** the feature implementation under its clean-architecture seams **When** ToolDispatchModeProvider.current returns the active dispatch mode **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`). | A18 | automated |
| AC-19 | 55 | 19. **Given** the feature implementation under its clean-architecture seams **When** ToolDispatchModeProvider.count returns 1 **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`). | A19 | automated |
| AC-20 | 56 | 20. **Given** the feature implementation under its clean-architecture seams **When** ToolCall holds toolName, arguments, executionMode **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`). | A20 | automated |
| AC-21 | 57 | 21. **Given** the feature implementation under its clean-architecture seams **When** ToolCall const constructor **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`). | A21 | automated |
| AC-22 | 58 | 22. **Given** the feature implementation under its clean-architecture seams **When** ToolDispatchResult round-trips through JSON with all 4 fields **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`). | A22 | automated |
| AC-23 | 59 | 23. **Given** the feature implementation under its clean-architecture seams **When** ToolDispatchResult error round-trip **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`). | A23 | automated |
| AC-24 | 60 | 24. **Given** the feature implementation under its clean-architecture seams **When** ToolDispatchResult.copyWith produces new instance **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`). | A24 | automated |
| AC-25 | 61 | 25. **Given** the feature implementation under its clean-architecture seams **When** ToolDispatchResult hasResult / noResult helpers **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`). | A25 | automated |
| AC-26 | 62 | 26. **Given** the feature implementation under its clean-architecture seams **When** ToolDispatchResult hasError / noError helpers **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`). | A26 | automated |
| AC-27 | 63 | 27. **Given** the feature implementation under its clean-architecture seams **When** ToolDispatchResult JSON encoding produces all keys **Then** the pinned regression test passes (`test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart`). | A27 | automated |

