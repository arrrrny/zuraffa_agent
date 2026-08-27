---
feature: 29-tool_call_signature-datasource-pair
loop: outside-in
profile: .specify/memory/tdd-profile.md
spec_criteria: 7
planned_at: 95f59a9
updated_at: 4547b6a
suite_baseline: green
---

# Test List: ToolCallSignature datasource + mock pair

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`. Each stays red until the feature works
end to end through its real entry point — the datasource public API.

| id  | behavior                                                                    | traces   | kind    | state   | test                                                                                    |
| --- | --------------------------------------------------------------------------- | -------- | ------- | ------- | --------------------------------------------------------------------------------------- |
| A1  | capture(sig) then lookup(sig.key) returns the equal signature (round-trip)  | AC US1-1 | example | DONE    | `test/data/datasources/tool_call_signature/tool_call_signature_mock_datasource_test.dart` |
| A2  | lookup of a never-captured key reports absence (null, no throw)             | AC US1-2 | example | DONE    | `test/data/datasources/tool_call_signature/tool_call_signature_mock_datasource_test.dart` |
| A3  | Equal content builds equal signatures with identical keys                   | AC US2-1 | example | DONE    | `test/domain/entities/tool_call_signature/tool_call_signature_test.dart`                 |
| A4  | Differing version (or name/hash) makes signatures unequal with different keys | AC US2-2 | example | DONE    | `test/domain/entities/tool_call_signature/tool_call_signature_test.dart`               |
| A5  | Capturing the same content twice holds one entry (idempotent capture)       | AC US2-3 | example | DONE    | `test/data/datasources/tool_call_signature/tool_call_signature_mock_datasource_test.dart` |
| A6  | count reflects distinct captured signatures                                | AC US3-1 | example | DONE    | `test/data/datasources/tool_call_signature/tool_call_signature_mock_datasource_test.dart` |
| A7  | reset() zeroes count and clears every lookup                               | AC US3-2 | example | DONE    | `test/data/datasources/tool_call_signature/tool_call_signature_mock_datasource_test.dart` |

## Inner loop: unit behaviors

Grouped by the component from `plan.md` that owns them.

### `lib/src/domain/entities/tool_call_signature/tool_call_signature.dart`

| id  | behavior                                                                    | traces         | kind    | state   | test                                                                      |
| --- | --------------------------------------------------------------------------- | -------------- | ------- | ------- | ------------------------------------------------------------------------- |
| U1  | Equal content ⇒ equal signatures and equal hashCodes                       | FR-001, SC-003 | example | DONE    | `test/domain/entities/tool_call_signature/tool_call_signature_test.dart` |
| U2  | Differing toolName, argumentHash or version ⇒ unequal signatures           | FR-001, SC-003 | example | DONE    | `test/domain/entities/tool_call_signature/tool_call_signature_test.dart` |
| U3  | key is the canonical 'toolName@version:argumentHash' string                | FR-002         | example | DONE    | `test/domain/entities/tool_call_signature/tool_call_signature_test.dart` |
| U4  | version defaults to 1                                                       | FR-003         | example | DONE    | `test/domain/entities/tool_call_signature/tool_call_signature_test.dart` |
| U5  | Legacy ToolCallSignature(id: ...) construction keeps compiling              | FR-003         | example | DONE    | `test/domain/entities/tool_call_signature/tool_call_signature_test.dart` |
| U6  | Equality ignores a legacy explicit id — the content triple decides          | FR-001, edge-3 | example | DONE    | `test/domain/entities/tool_call_signature/tool_call_signature_test.dart` |

### `lib/src/data/datasources/tool_call_signature/` (interface + mock)

| id  | behavior                                                                    | traces         | kind    | state   | test                                                                      |
| --- | --------------------------------------------------------------------------- | -------------- | ------- | ------- | ------------------------------------------------------------------------- |
| U7  | Mock implements the datasource interface (compile parity, issues #29/#30)   | FR-004         | example | BASELINE | `test/data/datasources/tool_call_signature/tool_call_signature_mock_datasource_test.dart` |
| U8  | lookup returns null for misses — typed as ToolCallSignature?                | FR-006         | example | DONE    | `test/data/datasources/tool_call_signature/tool_call_signature_mock_datasource_test.dart` |
| U9  | Empty toolName / argument hash are valid content with well-formed keys      | edge-4         | example | DONE    | `test/data/datasources/tool_call_signature/tool_call_signature_mock_datasource_test.dart` |

## Invariants and edge cases still to place

- The key must be stable across process restarts within a version — it is a
  pure function of content (covered by U3's format pin).
- reset must not affect any other store (spec 25's tracker) — separate
  instances by construction; no test coupling needed, documented in spec.

## Out of scope

- Signature → result caching (mapping to ToolResult): composes with spec 031;
  not this pair's surface.
- Cryptographic hashing of arguments (producing argumentHash): the caller's
  concern; this pair treats the hash as opaque content.
- Eviction policies (LRU/TTL) beyond reset: future backend concern.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md`:

- Single test: `dart test <file> --plain-name "<test name>"`
- Full suite: `dart test`
- Coverage: not configured (corroboration only, never a gate)
- Mutation (changed files): no tool configured — deliberate hand-mutants per
  `/speckit.tdd.verify` Phase 4
