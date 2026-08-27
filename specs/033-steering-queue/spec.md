# Feature Specification: SteeringQueue + SteeringMessage (R1 engine core) — enqueue/dispatch/inject semantics

**Feature Branch**: `feat/specs-032-033-034-035` (spec dir: `033-steering-queue`)

**Created**: 2026-08-24 | **Refined**: 2026-08-27 via /speckit.specify (drift remediation)

**Status**: Approved

**Input**: Verbatim task spec — "033-steering-queue — queue of steering messages injected mid-turn. Existing: lib/src/data/providers/steering_queue/steering_queue_provider.dart, lib/src/domain/services/steering_queue_service.dart, lib/src/domain/entities/steering_queue/steering_queue.dart, lib/src/domain/entities/steering_message/steering_message.dart, lib/src/engine/events/steering_injected.dart. Spec + tests for enqueue/dispatch/inject semantics."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Steering input is enqueued without disturbing the queue state (Priority: P1)

As the engine loop (pi-mono pattern: "mid-mission user input injected between turns without losing state"), when a steering message arrives mid-turn, I enqueue it onto the pending list and stamp `lastInjectedAt`, receiving a new immutable snapshot — the in-flight snapshot a consumer holds is never mutated under it.

**Why this priority**: Enqueue is the write side of the R1.3 contract; the scaffold's doc comments describe exactly this mutation model ("The engine mutates the queue by appending a message and returning a new snapshot (the snapshot itself is never mutated in place)") but ship NO `enqueue` method — documented behavior without API, the drift this feature remediates.

**Independent Test**: `queue.enqueue(message)` returns a snapshot whose pending list ends with the message and whose `lastInjectedAt == message.injectedAt`; the source queue is unchanged.

**Acceptance Scenarios**:

1. **Given** an empty queue, **When** a message is enqueued, **Then** the returned snapshot has `pendingCount == 1`, `head == message`, `isEmpty == false`, and `lastInjectedAt == message.injectedAt`.
2. **Given** a queue with one pending message, **When** a second message is enqueued, **Then** the returned snapshot's pending list is `[first, second]` (FIFO order preserved — `head` is still the first).
3. **Given** any queue, **When** `enqueue` is called, **Then** the source snapshot's pending list, `processedCount`, and `lastInjectedAt` are unchanged (state is never lost mid-turn).

---

### User Story 2 - The engine dispatches the head message FIFO and counts it processed (Priority: P1)

As the engine loop between turns, I pop the head steering message (the one the `SteeringInjected` event will carry), receive the drained queue as a new snapshot with `processedCount` incremented, and get a typed failure when popping an empty queue — never a silent null.

**Why this priority**: Dispatch is the read side of R1.3; the scaffold's SteeringMessage doc says "The engine pops messages FIFO and emits a `SteeringInjected` event per pop" but ships no `pop` API, and `processedCount` ("increments per pop") has no incrementing path. Both halves of the documented drain contract are missing.

**Independent Test**: `queue.pop()` returns `(message: head, queue: drained)` where drained has the head removed, `processedCount + 1`, `lastInjectedAt` preserved; popping an empty queue throws `StateError`.

**Acceptance Scenarios**:

1. **Given** a queue with pending `[m1, m2]`, **When** popped, **Then** the returned message is `m1`, the returned queue's pending is `[m2]`, `processedCount` is `old + 1`, and `lastInjectedAt` is preserved.
2. **Given** an empty queue, **When** popped, **Then** a `StateError` is thrown (typed failure — the engine only pops when non-empty; a silent null would fabricate a steering injection).
3. **Given** a queue with pending `[m1, m2]`, **When** popped twice, **Then** the messages come out `m1` then `m2` (FIFO drain order matches inject order) and the final queue is empty with `processedCount == old + 2`.

---

### User Story 3 - The queue and its messages survive the persistence boundary (Priority: P2)

As the persistence layer (the queue persists between turns; the session tree reconstructs the steering timeline), I serialize the queue and each message to JSON and parse them back without losing FIFO order, the processed count, or the injection timestamps.

**Why this priority**: The queue lives between turns — across an engine restart or a store round-trip it must survive intact; the scaffold has no serialization. Precedent: specs 031/032 landed `toJson`/`fromJson` for exactly this boundary.

**Independent Test**: `SteeringQueue.fromJson(queue.toJson()) == queue` for a populated queue (order, count, timestamps preserved); an empty queue round-trips with `lastInjectedAt` absent.

**Acceptance Scenarios**:

1. **Given** a populated queue (two pending, processedCount 3, lastInjectedAt set), **When** serialized and parsed back, **Then** the parsed queue equals the original on every field including FIFO order.
2. **Given** an empty fresh queue (lastInjectedAt null), **When** serialized, **Then** the `lastInjectedAt` key is absent — never fabricated — and the round-trip restores a null.
3. **Given** a steering message, **When** serialized and parsed back, **Then** id, content, and injectedAt round-trip exactly.

### Edge Cases

- Popping an empty queue → `StateError` with a message naming the queue id (AC US2-2).
- Mutating the list passed to the constructor after construction → the queue is unaffected (defensive copy — the scaffold stores the caller's reference, violating its own "immutable snapshot" claim).
- Writing to the queue's own `pending` list → throws (unmodifiable view — FR-001).
- Malformed queue/message JSON (missing required keys, non-string content) → `ArgumentError` naming the key; a non-list `pending` → `ArgumentError` (shape violations are typed errors).
- The `SteeringInjected` event emission per pop is the ENGINE's job (spec 002 territory); this feature ships the queue-side dispatch contract the event consumes — the event itself is not modified.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `SteeringQueue` MUST be a true immutable snapshot: the constructor MUST defensively copy [pending] into an unmodifiable list (mutations of the source list after construction do not affect the queue; direct writes to `queue.pending` throw). `SteeringMessage` keeps its three-field surface (`id`, `content`, `injectedAt`) and value equality.
- **FR-002**: `enqueue(SteeringMessage message)` MUST return a NEW snapshot with `pending + [message]` (FIFO append) and `lastInjectedAt == message.injectedAt`; `processedCount` and `id` are unchanged; the source snapshot is never mutated.
- **FR-003**: `pop()` MUST return a record `({SteeringMessage message, SteeringQueue queue})` where `message` is the current head, `queue` is a NEW snapshot with the head removed, `processedCount + 1`, `lastInjectedAt` preserved, and the remainder of the pending list in order; popping an empty queue MUST throw `StateError`. The source snapshot is never mutated.
- **FR-004**: `SteeringMessage.toJson()/fromJson()` MUST round-trip id, content, injectedAt exactly (ISO-8601 timestamp); `SteeringQueue.toJson()/fromJson()` MUST round-trip id, pending (nested message objects, FIFO order), processedCount, and lastInjectedAt-when-present; absent optionals serialize absent, never fabricated; missing/ill-typed required keys throw `ArgumentError` naming the key.
- **FR-005**: The `head`/`isEmpty`/`pendingCount` getters and value equality keep their existing semantics (compile parity with the 9 existing tests — equality stays deep over pending).
- **FR-006**: The clean-arch layers (`SteeringQueueService.current/count`, `SteeringQueueProvider`) keep their existing signatures and stubs (no behavioral change — the queue semantics are the deliverable).

### Key Entities *(include if feature involves data)*

- **SteeringMessage** (value object, existing scaffold): three-field surface + NEW `toJson`/`fromJson`.
- **SteeringQueue** (value object, existing scaffold): four-field surface + NEW pure transitions `enqueue`/`pop` + NEW `toJson`/`fromJson` + defensive immutability (FR-001).
- **SteeringInjected** (engine event, existing — NOT modified): the lifecycle event the engine emits per pop; the dispatch contract (FR-003) defines what the event carries.
- **SteeringQueueService / SteeringQueueProvider** (existing interfaces): unchanged surfaces; compile parity pinned by the existing 9 tests.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: enqueue appends FIFO, stamps lastInjectedAt, leaves the source unchanged (AC US1-1..3).
- **SC-002**: pop drains head FIFO, increments processedCount, preserves lastInjectedAt (AC US2-1, US2-3).
- **SC-003**: popping an empty queue is a typed `StateError` (AC US2-2).
- **SC-004**: queue + messages round-trip JSON field-exactly including FIFO order (AC US3-1, US3-3).
- **SC-005**: an empty queue serializes lastInjectedAt absent and restores null; malformed JSON throws `ArgumentError` (AC US3-2, edge-4).
- **SC-006**: the queue is a defensive immutable snapshot — source-list mutation and direct pending writes cannot corrupt it (edge-2, edge-3, FR-001).
- **SC-007**: `dart analyze --fatal-infos` zero new issues; full `dart test` green (post-032 baseline 611 passed); the 9 pre-existing provider tests pass unchanged (FR-005, FR-006).

## Assumptions

- `enqueue`/`pop` are additive (scaffold surface untouched), mirroring the CircuitBreaker pure-transition precedent and the spec-031/032 refinement precedents.
- `pop()` returning a Dart 3 record is idiomatic for this sdk (^3.8.0) and keeps the transition allocation-light; the alternative (a wrapper class) adds a type with no other purpose.
- The engine, not the queue, emits `SteeringInjected` (spec 002 boundary); FR-003's record is the queue-side contract.
- Timestamps in JSON are ISO-8601 strings; tests use `DateTime.utc` values that round-trip exactly.
- The provider/service layers stay stubs in this feature (FR-006): wiring them to a store is a separate feature.
- The scaffold's `hashCode` already folds the pending list via `Object.hashAll` — no hash remediation needed (unlike spec 034).
