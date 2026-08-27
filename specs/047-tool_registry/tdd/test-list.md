---
feature: 047-tool_registry
loop: inside-out
profile: .specify/memory/tdd-profile.md
spec_criteria: 8
planned_at: feat/specs-046-047-048-049
updated_at: feat/specs-046-047-048-049
suite_baseline: green
---

# Test List: ToolRegistry (single namespace)

## Outer loop: acceptance behaviors

| id  | behavior                                                                       | traces  | kind    | state | test                                                        |
| --- | ------------------------------------------------------------------------------ | ------- | ------- | ----- | ----------------------------------------------------------- |
| A1  | ToolRegistry is a const-constructible value object with 5 required fields      | AC-1    | example | DONE  | `test/data/providers/tool_registry/tool_registry_provider_test.dart` |
| A2  | Value equality holds when all 5 fields are identical                          | AC-2    | example | DONE  | `test/data/providers/tool_registry/tool_registry_provider_test.dart` |
| A3  | Inequality is detected when any single field differs (id, toolNames, counts)   | AC-2    | example | DONE  | `test/data/providers/tool_registry/tool_registry_provider_test.dart` |
| A4  | hashCode is consistent with == (equal instances share hashCode)               | AC-3    | example | DONE  | `test/data/providers/tool_registry/tool_registry_provider_test.dart` |
| A5  | ToolRegistryService is abstract with Loggable+FailureHandler mixins            | AC-4    | example | DONE  | `test/data/providers/tool_registry/tool_registry_provider_test.dart` |
| A6  | ToolRegistryProvider implements service; both methods throw UnimplementedError | AC-5  | example | DONE  | `test/data/providers/tool_registry/tool_registry_provider_test.dart` |
| A7  | toString includes id and toolNames                                            | AC-6    | example | DONE  | `test/data/providers/tool_registry/tool_registry_provider_test.dart` |
| A8  | Engine ToolRegistry abstract interface declares all 6 methods + onCollision stream | AC-7 | example | DONE | `test/data/providers/tool_registry/tool_registry_provider_test.dart` |
| A9  | NamespaceCollisionEvent holds toolName, sources, resolution                    | AC-8    | example | DONE  | `test/data/providers/tool_registry/tool_registry_provider_test.dart` |

## Inner loop: unit behaviors

### `lib/src/domain/entities/tool_registry/tool_registry.dart`

| id  | behavior                                                                       | traces  | kind    | state | test                                                        |
| --- | ------------------------------------------------------------------------------ | ------- | ------- | ----- | ----------------------------------------------------------- |
| U1  | Empty toolNames list is a valid value                                          | AC-1    | edge-1  | DONE  | `test/data/providers/tool_registry/tool_registry_provider_test.dart` |
| U2  | Zero counts are valid                                                           | AC-1    | edge-2  | DONE  | `test/data/providers/tool_registry/tool_registry_provider_test.dart` |

## Verification commands

- Single test: `dart test <file> --plain-name "<test name>"`
- Full suite: `dart test`
- Coverage: not configured (corroboration only, never a gate)
- Mutation (changed files): deliberate hand-mutants per `/speckit.tdd.verify` Phase 4
