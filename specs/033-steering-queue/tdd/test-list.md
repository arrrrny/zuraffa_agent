# Test List: 033-steering-queue

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | the returned snapshot has `pendingCount == 1`, `head == message`, `isEmpty == false`, and `lastInjectedAt == message.injectedAt`. | AC-1 | PENDING |
| A2 | the returned snapshot's pending list is `[first, second]` (FIFO order preserved — `head` is still the first). | AC-2 | PENDING |
| A3 | the source snapshot's pending list, `processedCount`, and `lastInjectedAt` are unchanged (state is never lost mid-turn). | AC-3 | PENDING |
| A4 | the returned message is `m1`, the returned queue's pending is `[m2]`, `processedCount` is `old + 1`, and `lastInjectedAt` is preserved. | AC-4 | PENDING |
| A5 | a `StateError` is thrown (typed failure — the engine only pops when non-empty; a silent null would fabricate a steering injection). | AC-5 | PENDING |
| A6 | the messages come out `m1` then `m2` (FIFO drain order matches inject order) and the final queue is empty with `processedCount == old + 2`. | AC-6 | PENDING |
| A7 | the parsed queue equals the original on every field including FIFO order. | AC-7 | PENDING |
| A8 | the `lastInjectedAt` key is absent — never fabricated — and the round-trip restores a null. | AC-8 | PENDING |
| A9 | id, content, and injectedAt round-trip exactly. | AC-9 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | `SteeringQueue` MUST be a true immutable snapshot: the constructor MUST defensively copy [pending] into an unmodifiable list (mutations of the source list after construction do not affect the queue; direct writes to `queue.pending` throw). `SteeringMessage` keeps its three-field surface (`id`, `content`, `injectedAt`) and value equality. | FR-001 | PENDING |
| U2 | `enqueue(SteeringMessage message)` MUST return a NEW snapshot with `pending + [message]` (FIFO append) and `lastInjectedAt == message.injectedAt`; `processedCount` and `id` are unchanged; the source snapshot is never mutated. | FR-002 | PENDING |
| U3 | `pop()` MUST return a record `({SteeringMessage message, SteeringQueue queue})` where `message` is the current head, `queue` is a NEW snapshot with the head removed, `processedCount + 1`, `lastInjectedAt` preserved, and the remainder of the pending list in order; popping an empty queue MUST throw `StateError`. The source snapshot is never mutated. | FR-003 | PENDING |
| U4 | `SteeringMessage.toJson()/fromJson()` MUST round-trip id, content, injectedAt exactly (ISO-8601 timestamp); `SteeringQueue.toJson()/fromJson()` MUST round-trip id, pending (nested message objects, FIFO order), processedCount, and lastInjectedAt-when-present; absent optionals serialize absent, never fabricated; missing/ill-typed required keys throw `ArgumentError` naming the key. | FR-004 | PENDING |
| U5 | The system MUST satisfy this requirement: The `head`/`isEmpty`/`pendingCount` getters and value equality keep their existing semantics (compile parity with the 9 existing tests — equality stays deep over pending). | FR-005 | PENDING |
| U6 | The system MUST satisfy this requirement: The clean-arch layers (`SteeringQueueService.current/count`, `SteeringQueueProvider`) keep their existing signatures and stubs (no behavioral change — the queue semantics are the deliverable). | FR-006 | PENDING |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 26]
route: A2 -> acceptance lane [declared: type marker, spec line 28]
route: A3 -> acceptance lane [declared: type marker, spec line 30]
route: A4 -> acceptance lane [declared: type marker, spec line 45]
route: A5 -> acceptance lane [declared: type marker, spec line 47]
route: A6 -> acceptance lane [declared: type marker, spec line 49]
route: A7 -> acceptance lane [declared: type marker, spec line 64]
route: A8 -> acceptance lane [declared: type marker, spec line 66]
route: A9 -> acceptance lane [declared: type marker, spec line 68]
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U6 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

