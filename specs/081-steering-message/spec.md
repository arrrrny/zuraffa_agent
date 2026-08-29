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
- **FR-003**: `SteeringMessage.fromJson(Map<String, dynamic> json)`
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
- **FR-008** (gates): `dart analyze --fatal-infos` exit 0 on the
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
