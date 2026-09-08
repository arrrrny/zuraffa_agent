**Template Version**: `zuraffa-1.0`

# Feature Specification: R1 — Steering Message value object (JSON contract & equality)

**Branch**: `081-steering-message` (off master `29b7fef`) | **Date**: 2026-08-29

## Summary

The engine needs a value object representing mid-mission user input
injected between turns: a typed carrier for the message that sits in
the `SteeringQueue` waiting to be drained by the engine loop. The
repo already ships `lib/src/domain/entities/steering_message/steering_message.dart`
— a hand-curated value object (PR #19 / spec 033's persistence
contract refinement) that:

- declares three required fields: `id` (UUID or equivalent),
  `content` (the text appended to the running turn's user-role
  context), and `injectedAt` (when the message entered the queue);
- serializes to JSON via `toJson()` (`{id, content, injectedAt}` with
  ISO-8601 timestamp);
- deserializes via `fromJson()` factory with typed `ArgumentError`
  on every malformed-input variant (missing key, wrong type,
  unparseable timestamp);
- overrides `==` and `hashCode` for full-field equality across all
  three fields.

What this spec closes is the **test coverage gap**: the file ships
without a dedicated test file. There is no test that pins the
lossless round-trip, the typed error contract, or the equality
contract on edge cases (empty content, unicode, off UTC boundaries).
A single refactor of this value object could silently break the
queue's persistence boundary or the session tree's reconstruction
of the steering timeline, and CI would not catch it.

This spec:

1. **Authors the spec-kit artifacts** (`spec.md`, `plan.md`,
   `tasks.md`, `tdd/test-list.md`, `tdd/verification.md`) for the
   value object — closing the documentation gap so the contract is
   explicit and reviewable.
2. **Adds a comprehensive test file** `test/domain/entities/steering_message/steering_message_test.dart`
   covering: lossless JSON round-trip (the persistence contract);
   every typed-error variant; equality on all three fields; edge
   cases (empty content, unicode in id and content, non-UTC timestamps,
   microsecond precision, large payloads).
3. **Does NOT change the implementation.** The value object is
   already spec-exact; this spec's contribution is the test suite
   and the spec-kit artifacts that pin its behavior.

**Out of scope, documented deviation**: the `SteeringQueue` itself
(spec 033's behavior, including FIFO ordering and the
`SteeringInjected` event emission) is not re-tested here — the queue
has its own test file (`test/domain/entities/steering_queue/steering_queue_test.dart`).
This spec only covers the atomic `SteeringMessage` value object.

## Files

- `lib/src/domain/entities/steering_message/steering_message.dart` —
  UNCHANGED. The file already implements every FR in this spec; this
  spec's contribution is the test suite and the spec-kit artifacts.
  Listed here for traceability.
- `test/domain/entities/steering_message/steering_message_test.dart` —
  NEW: comprehensive coverage for the value object — round-trip,
  typed errors, equality, edge cases. Lives in the conventional
  `test/domain/entities/<entity>/` mirror of `lib/src/domain/entities/<entity>/`,
  matching the existing `steering_queue/steering_queue_test.dart`
  pattern.
- `specs/081-steering-message/spec.md`,
  `specs/081-steering-message/plan.md`,
  `specs/081-steering-message/tasks.md`,
  `specs/081-steering-message/tdd/test-list.md`,
  `specs/081-steering-message/tdd/verification.md` — NEW.

## User scenarios

### US1 — A steering message round-trips through JSON (P1)

As an engine-integration author, I serialize a `SteeringMessage`
with `toJson` and parse it back with `fromJson`; the result equals
the original (lossless round-trip). The JSON shape is exactly
`{id, content, injectedAt}` — no extra keys, no omitted fields.

**Independent test**: a message with id `msg-1`, content `please focus`,
and a UTC timestamp → `toJson` → `fromJson` → equals the original.

### US2 — Malformed input throws typed ArgumentError (P1)

As an engine-integration author, when `fromJson` is given a map
missing a required field, with a field of the wrong type, or with
an unparseable timestamp, it throws `ArgumentError` whose `.name`
property identifies the offending key — never a generic
`FormatException` or `TypeError`, never a silent default.

**Independent test**: each malformed-input variant (missing `id`,
missing `content`, missing `injectedAt`, `id` not a string,
`content` not a string, `injectedAt` not a string, `injectedAt`
unparseable) throws `ArgumentError` with the right `.name`.

### US3 — Equality compares all three fields (P2)

As an engine-loop author, two `SteeringMessage`s are equal iff
their `id`, `content`, AND `injectedAt` fields are all equal. Any
field differing breaks equality; `hashCode` agrees with `==`.

**Independent test**: two messages with the same id+content+timestamp
compare equal; mutating any one field breaks equality; `hashCode`
matches.

### US4 — Edge cases survive the round-trip (P2)

As an engine-integration author, edge cases that occur in real
steering input — empty content (a steering message with no text,
useful as a heartbeat), unicode in id and content (Chinese,
emoji, RTL text), non-UTC timestamps, and microsecond precision —
all round-trip losslessly.

**Independent test**: each edge case variant round-trips to an
equal `SteeringMessage`.

## Requirements

### Functional requirements

- **FR-001**: `SteeringMessage` MUST be a value object with three
  required fields: `String id`, `String content`, `DateTime injectedAt`.
  All three are required at construction; none has a default.
- **FR-002**: `SteeringMessage.toJson()` MUST return a
  `Map<String, dynamic>` of shape `{id: <string>, content: <string>,
  injectedAt: <ISO-8601 string>}` — exactly three keys, no extras,
  no omissions. The timestamp MUST be `DateTime.toIso8601String()`
  output (UTC instants round-trip exactly).
- **FR-003**: The system MUST satisfy this requirement: `SteeringMessage.fromJson(Map<String, dynamic> json)`
  MUST produce a `SteeringMessage` equal (by FR-005) to the original
  that was serialized with `toJson` — lossless round-trip.
- **FR-004**: `SteeringMessage.fromJson` MUST throw `ArgumentError`
  (via `ArgumentError.value` with the offending value, name, and
  message) when:
  - `id` is missing or not a `String` — `.name = 'id'`;
  - `content` is missing or not a `String` — `.name = 'content'`;
  - `injectedAt` is missing or not a `String` — `.name = 'injectedAt'`;
  - `injectedAt` is a `String` but cannot be parsed by
    `DateTime.tryParse` — `.name = 'injectedAt'` (message indicates
    "not a parseable ISO-8601 timestamp").
- **FR-005**: `SteeringMessage.==` MUST return `true` iff both
  objects are `SteeringMessage` instances AND their `id`, `content`,
  and `injectedAt` fields are all equal. Identity short-circuits to
  `true`. `hashCode` MUST agree with `==` (two equal messages
  produce equal hashCodes).
- **FR-006**: Edge cases that MUST round-trip losslessly:
  - empty `content` (length 0);
  - unicode in `id` and `content` (Chinese, emoji, RTL text);
  - non-UTC `injectedAt` (with explicit timezone offset);
  - microsecond precision in `injectedAt`;
  - large `content` (>= 10 KB).
- **FR-007**: `SteeringMessage.toString()` MUST return a human-readable
  string naming the type and the three fields (with content truncated
  to 40 characters to avoid log bloat for long messages).
- **FR-008**: The system MUST satisfy this requirement: (gates): `dart analyze --fatal-infos` exit 0 on the
  changed files; full `dart test` green (baseline + new).

### Key entities

- `SteeringMessage` — value object: `id`, `content`, `injectedAt`,
  `toJson()`, `fromJson()` factory, `==`, `hashCode`, `toString()`.
  Plain Dart class (constitution IX exemption — same precedent as
  `AgentSession` PR #50, `ToolResult` PR #49, `StopPolicy` PR #47,
  `EpisodicMemory` — the file already ships hand-curated without
  `@Zorphy`).

## Success criteria

- **SC-001**: A `SteeringMessage` with arbitrary id + content + UTC
  timestamp round-trips through `toJson` → `fromJson` to an equal
  message (US1 / FR-002 / FR-003).
- **SC-002**: Every malformed-input variant (missing key, wrong type,
  unparseable timestamp) throws `ArgumentError` with `.name` matching
  the offending key (US2 / FR-004).
- **SC-003**: Two messages with the same id+content+timestamp compare
  equal via `==`; mutating any one field breaks equality; `hashCode`
  agrees (US3 / FR-005).
- **SC-004**: Every edge case variant (empty content, unicode,
  non-UTC, microsecond precision, large payload) round-trips
  losslessly (US4 / FR-006).
- **SC-005**: Every pinned behavior (FR-001..FR-007) is guarded by a
  test that a deliberate mutant kills (mutation evidence in
  `tdd/verification.md`).

## Dependencies

- Builds on: master `29b7fef` — `lib/src/domain/entities/steering_message/steering_message.dart`
  already implements every FR in this spec (PR #19 + spec 033's
  refinement). This spec's contribution is the test suite + spec-kit
  artifacts that pin the behavior.
- Independent of: every other spec in flight — different file,
  different tests. Specs 079 (skill system) and 080 (agent message
  history) land on master separately; this spec branches from
  `29b7fef` so the three are independent.
- Related but out of scope: `SteeringQueue` (spec 033), the
  `SteeringInjected` event (PR #19), the engine loop's steering
  drain (spec 002). All consume `SteeringMessage`; none are changed
  by this spec.

## Acceptance Scenarios

> Derived verbatim from the feature's pinned regression suite.
> Behaviors are inherited-green: the cited tests pass unmodified in
> the repo suite (dart test, 1201 passing).
1. **Given** the feature implementation under its clean-architecture seams **When** U1: arbitrary values round-trip losslessly **Then** the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`).
   **Type**: acceptance
2. **Given** the feature implementation under its clean-architecture seams **When** U2: toJson shape has exactly three keys **Then** the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`).
   **Type**: acceptance
3. **Given** the feature implementation under its clean-architecture seams **When** U3: toJson injectedAt is ISO-8601 parseable **Then** the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`).
   **Type**: acceptance
4. **Given** the feature implementation under its clean-architecture seams **When** U4: missing id throws ArgumentError naming id **Then** the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`).
   **Type**: acceptance
5. **Given** the feature implementation under its clean-architecture seams **When** U5: non-string id throws ArgumentError naming id **Then** the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`).
   **Type**: acceptance
6. **Given** the feature implementation under its clean-architecture seams **When** U6: missing content throws ArgumentError naming content **Then** the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`).
   **Type**: acceptance
7. **Given** the feature implementation under its clean-architecture seams **When** U7: non-string content throws ArgumentError naming content **Then** the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`).
   **Type**: acceptance
8. **Given** the feature implementation under its clean-architecture seams **When** U8: missing injectedAt throws ArgumentError naming injectedAt **Then** the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`).
   **Type**: acceptance
9. **Given** the feature implementation under its clean-architecture seams **When** U9: non-string injectedAt throws ArgumentError naming injectedAt **Then** the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`).
   **Type**: acceptance
10. **Given** the feature implementation under its clean-architecture seams **When** U10: unparseable injectedAt throws ArgumentError naming injectedAt **Then** the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`).
   **Type**: acceptance
11. **Given** the feature implementation under its clean-architecture seams **When** U11: equal messages are == **Then** the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`).
   **Type**: acceptance
12. **Given** the feature implementation under its clean-architecture seams **When** U12: differing id breaks == **Then** the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`).
   **Type**: acceptance
13. **Given** the feature implementation under its clean-architecture seams **When** U13: differing content breaks == **Then** the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`).
   **Type**: acceptance
14. **Given** the feature implementation under its clean-architecture seams **When** U14: differing injectedAt breaks == **Then** the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`).
   **Type**: acceptance
15. **Given** the feature implementation under its clean-architecture seams **When** U15: hashCode agrees with == **Then** the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`).
   **Type**: acceptance
16. **Given** the feature implementation under its clean-architecture seams **When** U16: identity short-circuits **Then** the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`).
   **Type**: acceptance
17. **Given** the feature implementation under its clean-architecture seams **When** U17: empty content round-trips **Then** the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`).
   **Type**: acceptance
18. **Given** the feature implementation under its clean-architecture seams **When** U18: unicode id round-trips **Then** the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`).
   **Type**: acceptance
19. **Given** the feature implementation under its clean-architecture seams **When** U19: unicode content round-trips (Chinese, emoji, RTL) **Then** the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`).
   **Type**: acceptance
20. **Given** the feature implementation under its clean-architecture seams **When** U20: non-UTC timestamp round-trips **Then** the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`).
   **Type**: acceptance
21. **Given** the feature implementation under its clean-architecture seams **When** U21: microsecond precision round-trips **Then** the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`).
   **Type**: acceptance
22. **Given** the feature implementation under its clean-architecture seams **When** U22: large content (>= 10 KB) round-trips **Then** the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`).
   **Type**: acceptance
23. **Given** the feature implementation under its clean-architecture seams **When** U23: includes type name and id; long content truncated **Then** the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`).
   **Type**: acceptance
24. **Given** the feature implementation under its clean-architecture seams **When** A1: enqueue on an empty queue yields head==message, isEmpty false, lastInjectedAt stamped **Then** the pinned regression test passes (`test/domain/entities/steering_queue/steering_queue_test.dart`).
   **Type**: acceptance
25. **Given** the feature implementation under its clean-architecture seams **When** A2: enqueue on a loaded queue appends FIFO (head stays the first) **Then** the pinned regression test passes (`test/domain/entities/steering_queue/steering_queue_test.dart`).
   **Type**: acceptance
26. **Given** the feature implementation under its clean-architecture seams **When** A3: enqueue leaves the source snapshot fully unchanged (no state lost mid-turn) **Then** the pinned regression test passes (`test/domain/entities/steering_queue/steering_queue_test.dart`).
   **Type**: acceptance
27. **Given** the feature implementation under its clean-architecture seams **When** U1: mutating the constructor source list after construction does not affect the queue **Then** the pinned regression test passes (`test/domain/entities/steering_queue/steering_queue_test.dart`).
   **Type**: acceptance
28. **Given** the feature implementation under its clean-architecture seams **When** U2: direct writes to queue.pending throw (unmodifiable view) **Then** the pinned regression test passes (`test/domain/entities/steering_queue/steering_queue_test.dart`).
   **Type**: acceptance
29. **Given** the feature implementation under its clean-architecture seams **When** U4: enqueue preserves processedCount and id **Then** the pinned regression test passes (`test/domain/entities/steering_queue/steering_queue_test.dart`).
   **Type**: acceptance
30. **Given** the feature implementation under its clean-architecture seams **When** A4: pop returns the head and the drained queue with processedCount + 1 **Then** the pinned regression test passes (`test/domain/entities/steering_queue/steering_queue_test.dart`).
   **Type**: acceptance
31. **Given** the feature implementation under its clean-architecture seams **When** A5: pop on an empty queue throws StateError naming the queue id **Then** the pinned regression test passes (`test/domain/entities/steering_queue/steering_queue_test.dart`).
   **Type**: acceptance
32. **Given** the feature implementation under its clean-architecture seams **When** A6: double-pop drains FIFO and ends empty with processedCount + 2 **Then** the pinned regression test passes (`test/domain/entities/steering_queue/steering_queue_test.dart`).
   **Type**: acceptance
33. **Given** the feature implementation under its clean-architecture seams **When** U3: pop preserves lastInjectedAt on the drained queue **Then** the pinned regression test passes (`test/domain/entities/steering_queue/steering_queue_test.dart`).
   **Type**: acceptance
34. **Given** the feature implementation under its clean-architecture seams **When** A7: a populated queue round-trips JSON incl. FIFO order and processedCount **Then** the pinned regression test passes (`test/domain/entities/steering_queue/steering_queue_test.dart`).
   **Type**: acceptance
35. **Given** the feature implementation under its clean-architecture seams **When** A8: an empty queue serializes lastInjectedAt absent and restores null **Then** the pinned regression test passes (`test/domain/entities/steering_queue/steering_queue_test.dart`).
   **Type**: acceptance
36. **Given** the feature implementation under its clean-architecture seams **When** A9: a steering message round-trips JSON (id, content, injectedAt) **Then** the pinned regression test passes (`test/domain/entities/steering_queue/steering_queue_test.dart`).
   **Type**: acceptance
37. **Given** the feature implementation under its clean-architecture seams **When** U5: malformed queue JSON throws ArgumentError (missing id, non-list pending, non-map entry) **Then** the pinned regression test passes (`test/domain/entities/steering_queue/steering_queue_test.dart`).
   **Type**: acceptance
38. **Given** the feature implementation under its clean-architecture seams **When** U6: malformed message JSON throws ArgumentError naming the key **Then** the pinned regression test passes (`test/domain/entities/steering_queue/steering_queue_test.dart`).
   **Type**: acceptance
