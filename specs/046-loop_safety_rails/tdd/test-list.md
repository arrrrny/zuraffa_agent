---
feature: 046-loop_safety_rails
loop: inside-out
profile: .specify/memory/tdd-profile.md
spec_criteria: 6
planned_at: feat/specs-046-047-048-049
updated_at: feat/specs-046-047-048-049
suite_baseline: green
---

# Test List: LoopSafetyRails typed outcomes

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`. The feature is a pure value object
with no user-visible surface of its own, so the loop runs inside-out: the
acceptance behaviors are exercised through the value object's public API
(constructors, getters, equality, toString) — which IS the real entry point a
consumer uses.

| id  | behavior                                                                       | traces  | kind    | state | test                                                        |
| --- | ------------------------------------------------------------------------------ | ------- | ------- | ----- | ----------------------------------------------------------- |
| A1  | LoopSafetyRails is a const-constructible value object with 4 required fields    | AC-1    | example | DONE  | `test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart` |
| A2  | Value equality holds when all 4 fields are identical                           | AC-2    | example | DONE  | `test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart` |
| A3  | Inequality is detected when any single field differs                           | AC-2    | example | DONE  | `test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart` |
| A4  | hashCode is consistent with == (equal instances share hashCode)                | AC-3    | example | DONE  | `test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart` |
| A5  | LoopSafetyRailsService is abstract with Loggable+FailureHandler mixins          | AC-4    | example | DONE  | `test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart` |
| A6  | LoopSafetyRailsProvider implements service; both methods throw UnimplementedError | AC-5 | example | DONE | `test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart` |
| A7  | toString includes outcomeType and turnNumber                                  | AC-6    | example | DONE  | `test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart` |

## Inner loop: unit behaviors

### `lib/src/domain/entities/loop_safety_rails/loop_safety_rails.dart`

| id  | behavior                                                                       | traces  | kind    | state | test                                                        |
| --- | ------------------------------------------------------------------------------ | ------- | ------- | ----- | ----------------------------------------------------------- |
| U1  | Identical instances are equal via identical() shortcut                         | AC-2    | example | DONE  | `test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart` |
| U2  | Different runtimeType prevents equality                                        | AC-2    | edge-1  | DONE  | (covered by value-equality tests — plain class, no subtypes) |

### `lib/src/data/providers/loop_safety_rails/loop_safety_rails_provider.dart`

| id  | behavior                                                                       | traces  | kind    | state | test                                                        |
| --- | ------------------------------------------------------------------------------ | ------- | ------- | ----- | ----------------------------------------------------------- |
| U3  | Provider constructor takes no arguments                                        | AC-5    | example | DONE  | `test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart` |

## Verification commands

- Single test: `dart test <file> --plain-name "<test name>"`
- Full suite: `dart test`
- Coverage: not configured (corroboration only, never a gate)
- Mutation (changed files): deliberate hand-mutants per `/speckit.tdd.verify` Phase 4
