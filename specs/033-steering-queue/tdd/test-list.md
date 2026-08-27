---
feature: 033-steering-queue
loop: inside-out
profile: .specify/memory/tdd-profile.md
spec_criteria: 9 # acceptance criteria AC US1-1..3, US2-1..3, US3-1..3 in spec.md
planned_at: e9fbc07
updated_at: e9fbc07
suite_baseline: green # 611 passed, 0 failed (post spec-032)
---

# Test List: SteeringQueue + SteeringMessage — enqueue/dispatch/inject semantics

## Outer loop: acceptance behaviors

The feature is a pure value-object pair with no user-visible surface of its
own, so the loop runs inside-out: acceptance behaviors are exercised through
the queue's public API (transitions + serialization) — the entry point the
engine loop and the persistence layer each consume.

| id  | behavior                                                                       | traces     | kind    | state   | test                                                            |
| --- | ------------------------------------------------------------------------------ | ---------- | ------- | ------- | ---------------------------------------------------------------- |
| A1  | enqueue on an empty queue yields head==message, isEmpty false, lastInjectedAt stamped | AC US1-1 | example | PENDING |                                                                  |
| A2  | enqueue on a loaded queue appends FIFO (head stays the first)                  | AC US1-2   | example | PENDING |                                                                  |
| A3  | enqueue leaves the source snapshot fully unchanged (no state lost mid-turn)    | AC US1-3   | example | PENDING |                                                                  |
| A4  | pop returns the head and the drained queue with processedCount + 1            | AC US2-1   | example | PENDING |                                                                  |
| A5  | pop on an empty queue throws StateError naming the queue id                    | AC US2-2   | example | PENDING |                                                                  |
| A6  | double-pop drains FIFO and ends empty with processedCount + 2                 | AC US2-3   | example | PENDING |                                                                  |
| A7  | a populated queue round-trips JSON incl. FIFO order and processedCount        | AC US3-1   | example | PENDING |                                                                  |
| A8  | an empty queue serializes lastInjectedAt absent and restores null             | AC US3-2   | example | PENDING |                                                                  |
| A9  | a steering message round-trips JSON (id, content, injectedAt)                  | AC US3-3   | example | PENDING |                                                                  |

## Inner loop: unit behaviors

Grouped by the component from `plan.md` that owns them.

### `lib/src/domain/entities/steering_queue/steering_queue.dart` (immutability)

| id  | behavior                                                                       | traces     | kind    | state   | test                                                            |
| --- | ------------------------------------------------------------------------------ | ---------- | ------- | ------- | ---------------------------------------------------------------- |
| U1  | mutating the constructor's source list after construction does not affect the queue | edge-2, FR-001 | example | PENDING |                                                              |
| U2  | direct writes to queue.pending throw (unmodifiable view)                       | edge-3, FR-001 | example | PENDING |                                                                |

### `lib/src/domain/entities/steering_queue/steering_queue.dart` (transitions)

| id  | behavior                                                                       | traces     | kind    | state   | test                                                            |
| --- | ------------------------------------------------------------------------------ | ---------- | ------- | ------- | ---------------------------------------------------------------- |
| U3  | pop preserves lastInjectedAt on the drained queue                              | FR-003     | example | PENDING |                                                                  |
| U4  | enqueue preserves processedCount and id                                        | FR-002     | example | PENDING |                                                                  |

### `lib/src/domain/entities/steering_queue/steering_queue.dart` (persistence)

| id  | behavior                                                                       | traces     | kind    | state   | test                                                            |
| --- | ------------------------------------------------------------------------------ | ---------- | ------- | ------- | ---------------------------------------------------------------- |
| U5  | malformed queue JSON throws ArgumentError (missing id, non-list pending, non-map entry) | edge-4, FR-004 | example | PENDING |                                                       |
| U6  | malformed message JSON throws ArgumentError naming the key                     | edge-4, FR-004 | example | PENDING |                                                                |
| U7  | The 9 pre-existing provider/compile-parity tests keep passing unchanged        | FR-005, FR-006 | BASELINE | BASELINE | `test/data/providers/steering_queue/steering_queue_provider_test.dart` |

## Invariants and edge cases still to place

- Snapshot immutability under transition: covered as first-class acceptance behavior A3 and unit behaviors U1/U2 — the queue is never corrupted mid-turn.
- Absent-never-fabricated serialization: covered by A8 (lastInjectedAt) — the house discipline from 031/032.
- FIFO drain order == inject order: covered by A6 (the sequence assertion).

## Out of scope

- Emitting `SteeringInjected` on pop: the ENGINE's job (spec 002 boundary) — FR-003 ships the queue-side contract the event consumes.
- Wiring `SteeringQueueProvider` to a real store: separate feature (FR-006 keeps the stubs).
- Multimodal steering content (parts beyond text): later R2 concern per the scaffold's SteeringMessage doc.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md` at planning time:

- Single test: `dart test test/domain/entities/steering_queue/steering_queue_test.dart -n "<name>"`
- File: `dart test test/domain/entities/steering_queue/steering_queue_test.dart`
- Full suite: `dart test`
- Mutation (changed files): no tool wired — deliberate hand-mutants per the profile

## Mutation targets (deliberate-mutant sampling)

| target | mutant | killed by |
| ------ | ------ | --------- |
| enqueue stamp | enqueue keeps the old lastInjectedAt | A1 |
| pop drain | pop drops the processedCount increment | A4 |
| defensive copy | constructor stores the caller's reference (scaffold behavior) | U1 |
| FIFO order | pop returns the last pending instead of the head | A4/A6 |
