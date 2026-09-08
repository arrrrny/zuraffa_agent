# Traceability: 033-steering-queue

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:efe6e4eb60c317bb07e3230aedec2793dcb134d0a6c07ed7290fcbe2e57d4a10
statements: 15
automated: 15
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 25 | 1. **Given** an empty queue, **When** a message is enqueued, **Then** the returned snapshot has `pendingCount == 1`, `head == message`, `isEmpty == false`, and `lastInjectedAt == message.injectedAt`. | A1 | automated |
| AC-2 | 27 | 2. **Given** a queue with one pending message, **When** a second message is enqueued, **Then** the returned snapshot's pending list is `[first, second]` (FIFO order preserved — `head` is still the first). | A2 | automated |
| AC-3 | 29 | 3. **Given** any queue, **When** `enqueue` is called, **Then** the source snapshot's pending list, `processedCount`, and `lastInjectedAt` are unchanged (state is never lost mid-turn). | A3 | automated |
| AC-4 | 44 | 4. **Given** a queue with pending `[m1, m2]`, **When** popped, **Then** the returned message is `m1`, the returned queue's pending is `[m2]`, `processedCount` is `old + 1`, and `lastInjectedAt` is preserved. | A4 | automated |
| AC-5 | 46 | 5. **Given** an empty queue, **When** popped, **Then** a `StateError` is thrown (typed failure — the engine only pops when non-empty; a silent null would fabricate a steering injection). | A5 | automated |
| AC-6 | 48 | 6. **Given** a queue with pending `[m1, m2]`, **When** popped twice, **Then** the messages come out `m1` then `m2` (FIFO drain order matches inject order) and the final queue is empty with `processedCount == old + 2`. | A6 | automated |
| AC-7 | 63 | 7. **Given** a populated queue (two pending, processedCount 3, lastInjectedAt set), **When** serialized and parsed back, **Then** the parsed queue equals the original on every field including FIFO order. | A7 | automated |
| AC-8 | 65 | 8. **Given** an empty fresh queue (lastInjectedAt null), **When** serialized, **Then** the `lastInjectedAt` key is absent — never fabricated — and the round-trip restores a null. | A8 | automated |
| AC-9 | 67 | 9. **Given** a steering message, **When** serialized and parsed back, **Then** id, content, and injectedAt round-trip exactly. | A9 | automated |
| FR-001 | 82 | - **FR-001**: `SteeringQueue` MUST be a true immutable snapshot: the constructor MUST defensively copy [pending] into an unmodifiable list (mutations of the source list after construction do not affect the queue; direct writes to `queue.pending` throw). `SteeringMessage` keeps its three-field surface (`id`, `content`, `injectedAt`) and value equality. | U1 | automated |
| FR-002 | 83 | - **FR-002**: `enqueue(SteeringMessage message)` MUST return a NEW snapshot with `pending + [message]` (FIFO append) and `lastInjectedAt == message.injectedAt`; `processedCount` and `id` are unchanged; the source snapshot is never mutated. | U2 | automated |
| FR-003 | 84 | - **FR-003**: `pop()` MUST return a record `({SteeringMessage message, SteeringQueue queue})` where `message` is the current head, `queue` is a NEW snapshot with the head removed, `processedCount + 1`, `lastInjectedAt` preserved, and the remainder of the pending list in order; popping an empty queue MUST throw `StateError`. The source snapshot is never mutated. | U3 | automated |
| FR-004 | 85 | - **FR-004**: `SteeringMessage.toJson()/fromJson()` MUST round-trip id, content, injectedAt exactly (ISO-8601 timestamp); `SteeringQueue.toJson()/fromJson()` MUST round-trip id, pending (nested message objects, FIFO order), processedCount, and lastInjectedAt-when-present; absent optionals serialize absent, never fabricated; missing/ill-typed required keys throw `ArgumentError` naming the key. | U4 | automated |
| FR-005 | 86 | - **FR-005**: The system MUST satisfy this requirement: The `head`/`isEmpty`/`pendingCount` getters and value equality keep their existing semantics (compile parity with the 9 existing tests — equality stays deep over pending). | U5 | automated |
| FR-006 | 87 | - **FR-006**: The system MUST satisfy this requirement: The clean-arch layers (`SteeringQueueService.current/count`, `SteeringQueueProvider`) keep their existing signatures and stubs (no behavioral change — the queue semantics are the deliverable). | U6 | automated |

