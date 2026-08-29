# Feature Specification: Steering Message value object

**Feature Branch**: `081-steering-message`

**Created**: 2026-08-29

**Status**: Draft

**Input**: User description: "Well-defined spec for the Steering Message value object — mid-mission user input that sits in the steering queue — including its JSON contract and equality, that is not yet covered by an existing spec (R1)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Capture mid-mission user input (Priority: P1)

While the engine loop runs, the user can inject follow-up input. That input is captured as a `SteeringMessage` (id, content, injectedAt) and placed on the steering queue; the engine pops it FIFO and emits a `SteeringInjected` event per message.

**Why this priority**: The value object is the atomic unit of mid-mission steering; correctness of its fields and serialization underpins the whole steering flow (spec 033 covers the queue, not this object).

**Independent Test**: Can be fully tested by constructing a `SteeringMessage`, round-tripping through `toJson`/`fromJson`, and asserting field equality.

**Acceptance Scenarios**:

1. **Given** a steering message with id `u1`, content `"do X"`, time `T`, **When** serialized and parsed back, **Then** the result equals the original with identical id/content/injectedAt.
2. **Given** a JSON map missing `content`, **When** parsed, **Then** an `ArgumentError` is thrown naming `content`.

---

### User Story 2 - Survive the store boundary (Priority: P2)

Steering messages persist between turns via the session store. The serialization contract must round-trip exactly: ISO-8601 UTC timestamps, no fabricated defaults, and a typed error on malformed input.

**Why this priority**: A dropped or mutated field would corrupt the steering timeline in the session tree.

**Independent Test**: Can be fully tested by asserting `fromJson` rejects missing fields, non-string types, and unparseable timestamps, and that `toJson` never omits a required field.

**Acceptance Scenarios**:

1. **Given** a JSON map where `injectedAt` is `"not-a-date"`, **When** parsed, **Then** an `ArgumentError` is thrown naming `injectedAt`.
2. **Given** a valid message, **When** `toJson` is called, **Then** all three fields (`id`, `content`, `injectedAt`) are present and `injectedAt` is an ISO-8601 string.

---

### Edge Cases

- `id`/`content` must be non-null strings; a null or wrong-typed value throws `ArgumentError` naming the key.
- `injectedAt` must be a parseable ISO-8601 string; `DateTime.tryParse` failure throws with a clear message.
- `fromJson` never fabricates defaults — every required field is enforced.
- Equality and `hashCode` cover all three fields so two messages differing in any field are distinct.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `SteeringMessage` MUST carry three required fields: `id` (String), `content` (String), `injectedAt` (DateTime).
- **FR-002**: `toJson` MUST serialize all three fields; `injectedAt` MUST be an ISO-8601 string (UTC instants round-trip exactly); no field is ever omitted.
- **FR-003**: `fromJson` MUST parse exactly and MUST throw `ArgumentError` naming the offending key when a required field is missing, ill-typed, or (for `injectedAt`) unparseable; it MUST NOT fabricate a default.
- **FR-004**: `operator ==` and `hashCode` MUST consider all three fields.

### Key Entities

- **SteeringMessage**: `{ id, content, injectedAt }` — a single piece of mid-mission user input awaiting draining by the engine.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A round-trip `toJson` → `fromJson` preserves `id`, `content`, and `injectedAt` exactly (byte-equal timestamps).
- **SC-002**: Malformed JSON (missing field, wrong type, bad timestamp) always throws `ArgumentError` and never returns a partial object.
- **SC-003**: Two messages differing in any single field are not equal and have distinct hash codes.

## Assumptions

- Steering is text-only for now; multimodal parts are a later R2 concern.
- The companion `SteeringQueue` and `SteeringInjected` event are owned by spec 033; this spec owns only the message value object and its contract.
- This feature maps to **R1 (engine core, issue #2)** — steering & follow-up queues.
