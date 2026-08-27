---
feature: 048-tool_dispatch_mode
loop: inside-out
profile: .specify/memory/tdd-profile.md
spec_criteria: 9
planned_at: feat/specs-046-047-048-049
updated_at: feat/specs-046-047-048-049
suite_baseline: green
---

# Test List: ToolDispatchMode (sequential/parallel)

## Outer loop: acceptance behaviors

| id  | behavior                                                                       | traces  | kind    | state | test                                                        |
| --- | ------------------------------------------------------------------------------ | ------- | ------- | ----- | ----------------------------------------------------------- |
| A1  | ToolDispatchMode is a const-constructible value object with 4 required fields  | AC-1    | example | DONE  | `test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart` |
| A2  | Value equality holds when all 4 fields are identical                          | AC-2    | example | DONE  | `test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart` |
| A3  | Inequality is detected when any single field differs                           | AC-2    | example | DONE  | `test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart` |
| A4  | hashCode is consistent with == (equal instances share hashCode)               | AC-3    | example | DONE  | `test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart` |
| A5  | ToolDispatchModeService is abstract with Loggable+FailureHandler mixins        | AC-4    | example | DONE  | `test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart` |
| A6  | ToolDispatchModeProvider implements service; both methods throw UnimplementedError | AC-5 | example | DONE | `test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart` |
| A7  | toString includes id, mode, and maxParallel                                   | AC-6    | example | DONE  | `test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart` |
| A8  | Engine ToolDispatcher declares dispatch, dispatchBatch, validateSchema, checkRiskTier | AC-7 | example | DONE | `test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart` |
| A9  | ToolCall holds toolName, arguments, executionMode                             | AC-8    | example | DONE  | `test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart` |
| A10 | ToolDispatchResult round-trips through JSON with all 4 fields                | AC-9    | example | DONE  | `test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart` |

## Inner loop: unit behaviors

### `lib/src/domain/entities/tool_dispatch_result/tool_dispatch_result.dart`

| id  | behavior                                                                       | traces  | kind    | state | test                                                        |
| --- | ------------------------------------------------------------------------------ | ------- | ------- | ----- | ----------------------------------------------------------- |
| U1  | ToolDispatchResult.copyWith produces a new instance with changed field        | AC-9    | example | DONE  | `test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart` |
| U2  | ToolDispatchResult.hasResult / noResult helpers reflect result field state    | AC-9    | example | DONE  | `test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart` |
| U3  | ToolDispatchResult.hasError / noError helpers reflect error field state        | AC-9    | example | DONE  | `test/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider_test.dart` |

## Verification commands

- Single test: `dart test <file> --plain-name "<test name>"`
- Full suite: `dart test`
- Coverage: not configured (corroboration only, never a gate)
- Mutation (changed files): deliberate hand-mutants per `/speckit.tdd.verify` Phase 4
