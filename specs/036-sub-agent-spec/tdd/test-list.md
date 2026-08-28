---
feature: 036-sub-agent-spec
loop: inside-out
profile: .specify/memory/tdd-profile.md
spec_criteria: 7
planned_at: 7da6902
updated_at: ca10fd6
suite_baseline: green
---

# Test List: SubAgentSpec value object (validation + pinned semantics)

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`. The feature is a pure value object with
no user-visible surface of its own, so the loop runs inside-out (`loop:
inside-out`): acceptance behaviors are exercised through the value object's public
API — the constructor and getters — which IS the entry point a consumer (the
future spec loader) uses.

| id  | behavior                                                                        | traces   | kind            | state   | test                                                        |
| --- | ------------------------------------------------------------------------------- | -------- | --------------- | ------- | ----------------------------------------------------------- |
| A1  | Empty name/description/systemPrompt construction throws ArgumentError           | AC US1-1 | example         | DONE    | `test/domain/entities/sub_agent_spec/sub_agent_spec_test.dart` |
| A2  | Blank tool id or sub-agent name in an allowlist throws ArgumentError            | AC US1-2 | example         | DONE    | `test/domain/entities/sub_agent_spec/sub_agent_spec_test.dart` |
| A3  | Non-positive budgets throw; zero-duration and null budgets stay valid           | AC US1-3 | example         | DONE    | `test/domain/entities/sub_agent_spec/sub_agent_spec_test.dart` |
| A4  | Self-extends (extendsSpec == name) throws; a distinct parent constructs         | AC US2-1 | example         | DONE    | `test/domain/entities/sub_agent_spec/sub_agent_spec_test.dart` |
| A5  | isLeaf/isRoot answer correctly across the four canonical shapes                 | AC US2-2 | characterization | DONE (BASELINE + pin) | provider suite (3 shapes) + `sub_agent_spec_test.dart` U10 pin (child+branch) |
| A6  | Ten-field equality holds with independently constructed (non-const) lists       | AC US3-1 | characterization | DONE (BASELINE + pin) | `sub_agent_spec_test.dart` U12 pin (mutant-B killed) |
| A7  | Single-field differences break equality                                         | AC US3-2 | characterization | DONE (BASELINE) | `test/data/providers/sub_agent_spec/sub_agent_spec_provider_test.dart` (tools + extends axes) |

## Inner loop: unit behaviors

Grouped by the component from `plan.md` that owns them.

### `lib/src/domain/entities/sub_agent_spec/sub_agent_spec.dart`

| id  | behavior                                                                        | traces   | kind            | state   | test                                                        |
| --- | ------------------------------------------------------------------------------- | -------- | --------------- | ------- | ----------------------------------------------------------- |
| U1  | Empty name throws ArgumentError naming 'name'                                   | FR-001   | example         | DONE    | `sub_agent_spec_test.dart` (red @ `1eb07a2`) |
| U2  | Empty description throws ArgumentError naming 'description'                     | FR-001   | example         | DONE    | `sub_agent_spec_test.dart` (red @ `1eb07a2`) |
| U3  | Empty systemPrompt throws ArgumentError naming 'systemPrompt'                   | FR-001   | example         | DONE    | `sub_agent_spec_test.dart` (red @ `1eb07a2`) |
| U4  | Blank id ('') inside tools throws ArgumentError naming 'tools'                  | FR-002   | example         | DONE    | `sub_agent_spec_test.dart` (red @ `9391515`) |
| U5  | Blank id ('') inside subAgents throws ArgumentError naming 'subAgents'          | FR-002   | example         | DONE    | `sub_agent_spec_test.dart` (red @ `9391515`) |
| U6  | maxTurns 0 throws, maxTurns 1 is valid (both sides of the boundary)             | FR-003   | example         | DONE    | `sub_agent_spec_test.dart` (red @ `d6062c0`) |
| U7  | contextWindowTokens 0 throws, 1 is valid (both sides of the boundary)           | FR-003   | example         | DONE    | `sub_agent_spec_test.dart` (red @ `d6062c0`) |
| U8  | Negative wallClockTimeout throws; Duration.zero valid; null valid               | FR-003   | example         | DONE    | `sub_agent_spec_test.dart` (red @ `d6062c0`) |
| U9  | extendsSpec == name throws 1-cycle ArgumentError; distinct parent valid         | FR-004   | example         | DONE    | `sub_agent_spec_test.dart` (red @ `953a0cd`) |
| U10 | isLeaf/isRoot across root+leaf, root+branch, child+leaf, child+branch            | FR-005   | characterization | DONE (BASELINE + pin, mutant-A killed) | provider suite + `sub_agent_spec_test.dart` |
| U11 | hasBudgets false (none) / true (all three) / true (only maxTurns)               | FR-005   | characterization | DONE (BASELINE) | `test/data/providers/sub_agent_spec/sub_agent_spec_provider_test.dart` |
| U12 | Equality + hashCode hold with non-const, independently built tools/subAgents    | FR-006   | characterization | DONE (BASELINE + pin, mutant-B killed) | `sub_agent_spec_test.dart` |
| U13 | Inequality on single-field change (tools axis, extends axis)                    | FR-006   | characterization | DONE (BASELINE) | `test/data/providers/sub_agent_spec/sub_agent_spec_provider_test.dart` |

### `lib/src/data/providers/sub_agent_spec/` + `lib/src/domain/services/` (layers untouched — FR-007)

| id  | behavior                                                                        | traces   | kind            | state   | test                                                        |
| --- | ------------------------------------------------------------------------------- | -------- | --------------- | ------- | ----------------------------------------------------------- |
| U14 | The 11 pre-existing compile-parity + stub tests keep passing unchanged          | FR-007   | characterization | DONE (BASELINE) | `test/data/providers/sub_agent_spec/sub_agent_spec_provider_test.dart` |

## Invariants and edge cases still to place

- `==`/`hashCode` consistency: the ten-field equality axes are reflected in
  `Object.hash` (lists via `Object.hashAll`) — pinned by U12; hash distribution
  itself is not deterministically assertable (031 precedent, M5 equivalent).
- Validation ordering is unspecified on purpose: any ArgumentError from a
  multi-invalid input satisfies the contract; tests use single-invalid inputs.

## Out of scope

- Wiring SubAgentSpecProvider to a registry (current/count behavior): separate
  feature; FR-007 pins the stubs.
- `extends` chain resolution beyond the 1-cycle check (unknown parents,
  deep cycles): the YAML loader spec (057-yaml_agent_spec lineage) owns it.
- String trimming/normalization of identity fields: loader's concern.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md`:

- Single test: `dart test <file> --plain-name "<test name>"`
- Full suite: `dart test`
- Coverage: raw VM-format only (`dart test --coverage=...`); converter absent —
  corroboration only, never a gate
- Mutation: no tool configured — deliberate hand-mutants per
  `/speckit.tdd.verify` Phase 4
