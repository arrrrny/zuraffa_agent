---
feature: 031-tool-result-value-object
loop: inside-out
profile: .specify/memory/tdd-profile.md
spec_criteria: 8
planned_at: a1934c3
updated_at: a1934c3
suite_baseline: green
---

# Test List: ToolResult value object

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`. The feature is a pure value object
with no user-visible surface of its own, so the loop runs inside-out: the
acceptance behaviors are exercised through the value object's public API
(constructors, getters, serialization) — which IS the real entry point a
consumer uses.

| id  | behavior                                                                       | traces   | kind    | state   | test                                                        |
| --- | ------------------------------------------------------------------------------ | -------- | ------- | ------- | ----------------------------------------------------------- |
| A1  | A success result with payload round-trips through JSON exactly                 | AC US1-1 | example | PENDING | `test/domain/entities/tool_result/tool_result_test.dart`    |
| A2  | An error result round-trips with isError true and content preserved            | AC US1-2 | example | PENDING | `test/domain/entities/tool_result/tool_result_test.dart`    |
| A3  | An error result without payload serializes without a payload key               | AC US1-3 | example | PENDING | `test/domain/entities/tool_result/tool_result_test.dart`    |
| A4  | The oversized path yields summary + artifactRef + isSummarized true            | AC US2-1 | example | PENDING | `test/domain/entities/tool_result/tool_result_test.dart`    |
| A5  | A summarized result's artifactRef survives the round-trip                      | AC US2-2 | example | PENDING | `test/domain/entities/tool_result/tool_result_test.dart`    |
| A6  | An inline result is isSummarized false and serializes without artifactRef      | AC US2-3 | example | PENDING | `test/domain/entities/tool_result/tool_result_test.dart`    |
| A7  | Equal results with distinct-but-equal payload instances share hashCode         | AC US3-1 | example | PENDING | `test/domain/entities/tool_result/tool_result_test.dart`    |
| A8  | Results differing in content/payload/isError/artifactRef are unequal           | AC US3-2 | example | PENDING | `test/domain/entities/tool_result/tool_result_test.dart`    |

## Inner loop: unit behaviors

Grouped by the component from `plan.md` that owns them.

### `lib/src/domain/entities/tool_result/tool_result.dart`

| id  | behavior                                                                       | traces         | kind    | state   | test                                                        |
| --- | ------------------------------------------------------------------------------ | -------------- | ------- | ------- | ----------------------------------------------------------- |
| U1  | success factory sets isError false; error factory sets isError true            | FR-002         | example | PENDING | `test/domain/entities/tool_result/tool_result_test.dart`    |
| U2  | Default construction stays isError=false (backward compat)                     | FR-001         | example | PENDING | `test/domain/entities/tool_result/tool_result_test.dart`    |
| U3  | isError participates in equality                                               | FR-002         | example | PENDING | `test/domain/entities/tool_result/tool_result_test.dart`    |
| U4  | Payload hashing is order-independent across insertion orders                   | FR-006         | example | PENDING | `test/domain/entities/tool_result/tool_result_test.dart`    |
| U5  | null payload equals null only — never an empty map                             | edge-1         | example | PENDING | `test/domain/entities/tool_result/tool_result_test.dart`    |
| U6  | oversized constructor requires summary + artifactRef (assert contract)         | FR-004         | example | PENDING | `test/domain/entities/tool_result/tool_result_test.dart`    |
| U7  | oversized error results are constructible (edge-5)                             | FR-004, edge-5 | example | PENDING | `test/domain/entities/tool_result/tool_result_test.dart`    |
| U8  | fromJson round-trips a ref with uri null (nullable uri survives)               | FR-003         | example | PENDING | `test/domain/entities/tool_result/tool_result_test.dart`    |

### `lib/src/data/providers/tool_result/` (layers untouched — FR-007)

| id  | behavior                                                                       | traces         | kind    | state   | test                                                        |
| --- | ------------------------------------------------------------------------------ | -------------- | ------- | ------- | ----------------------------------------------------------- |
| U9  | The 7 pre-existing compile-parity + stub tests keep passing unchanged           | FR-007         | BASELINE | BASELINE | `test/data/providers/tool_result/tool_result_provider_test.dart` |

## Invariants and edge cases still to place

- `==`/`hashCode` consistency: every equality axis (content, payload, isError,
  artifactRef) must be reflected in the hash — covered by A7/U4 + A8.
- Serialization must never fabricate structure: absent payload stays absent
  (A3), absent ref stays absent (A6).

## Out of scope

- Wiring ToolResultProvider to a store (current/count behavior): separate
  feature; FR-007 pins the stubs.
- Non-JSON-encodable payload values: caller pre-sanitizes (spec Assumption).
- The threshold decision itself (what counts as oversized): OversizedResultPolicy
  (spec 050) owns it; this pair only carries the summarized shape.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md`:

- Single test: `dart test <file> --plain-name "<test name>"`
- Full suite: `dart test`
- Coverage: not configured (corroboration only, never a gate)
- Mutation (changed files): no tool configured — deliberate hand-mutants per
  `/speckit.tdd.verify` Phase 4
