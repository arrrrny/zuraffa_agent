# Test List: R1 — Agent Message History (spec 080)

---
feature: 080-agent-message-history
loop: outside-in
profile: .specify/memory/tdd-profile.md # file absent at HEAD — rubric graded against the tdd-test-quality-rubric template + constitution.md Principles II/V/VII/IX
spec_criteria: 9 # FR-001..FR-009 in spec.md
planned_at: master (29b7fef)
updated_at: 080-agent-message-history (planned)
suite_baseline: 1073 passed / 2 skipped at 29b7fef (master)
suite_after: 1090 passed / 2 skipped at 080-agent-message-history HEAD (+17 new, 0 regressions)
---

## Outer loop: acceptance behaviors

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| A1  | Two histories built from equal-but-distinct message + memory lists compare equal via `==`; mutating either list breaks equality; `hashCode` agrees | FR-001, FR-002, US1 | example | PASSING | `test/llm/agent_message_history_080_test.dart::spec 080 — AgentMessageHistory::equality holds for equal histories and breaks for any field mutation` |
| A2  | A history with N messages + M memories round-trips through `toJson` → `fromJson` to an equal history (lossless) | FR-003, FR-004, US2 | example | PASSING | `…::toJson → fromJson round-trips an equal history` |
| A3  | Gates: `dart analyze --fatal-infos` exit 0 on the changed files; full `dart test` green (baseline 1073/2 + 17 new) | FR-009 | gate | PASSING | gates at branch HEAD (counts in verification.md) |

## Inner loop: unit behaviors

### Equality (FR-001 / FR-002)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U1  | Two histories with the SAME message + memory instances (different list wrappers) compare `==` | FR-001 | unit | PASSING | `…::equality — equal histories (same message instances + same memory instances) are ==` |
| U2  | Appending a message to one history's `messages` breaks `==` | FR-001 | unit | PASSING | `…::equality — appended message breaks ==` |
| U3  | Appending a memory to one history's `episodicMemories` breaks `==` | FR-001 | unit | PASSING | `…::equality — appended memory breaks ==` |
| U4  | `hashCode` agrees with `==` for the equal case (the only contractually-required property) | FR-002 | unit | PASSING | `…::equality — hashCode agrees with ==` |

### JSON round-trip (FR-003 / FR-004)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U5  | History with two messages + one memory → `toJson` → `fromJson` → produces a structurally-equal history (counts, roles, content text, memory id, summaries). Note: AgentMessage subclasses inherit Object identity equality, so the round-trip is asserted structurally rather than via `==` | FR-003, FR-004 | unit | PASSING | `…::JSON — round-trip preserves structural shape (lossless round-trip)` |
| U6  | Empty history (both lists empty) → `toJson` → `fromJson` → empty history with both lists empty and both JSON keys empty | FR-003, FR-004 | unit | PASSING | `…::JSON — empty history round-trips` |
| U7  | `toJson` produces exactly the two keys `messages` and `episodicMemories`; no extras | FR-003 | unit | PASSING | `…::JSON — toJson shape has exactly two keys` |

### truncate preserves memories — pinned by equality (FR-006)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U8  | `truncate(N).episodicMemories == receiver.episodicMemories` — equal by `==` (not just length) | FR-006, US3 | pin | PASSING | `…::truncate — episodicMemories survive via ==` |
| U9  | `truncate(0).episodicMemories == receiver.episodicMemories` — memories untouched even when active window is fully evicted | FR-006 | pin | PASSING | `…::truncate(0) — memories untouched when active window is fully evicted` |

### fromJson error paths (FR-005)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U10 | Missing `messages` key → `ArgumentError` naming `messages` | FR-005, US4 | unit | PASSING | `…::fromJson — missing messages throws ArgumentError naming messages` |
| U11 | `messages` is not a list (e.g. a string) → `ArgumentError` naming `messages` | FR-005 | unit | PASSING | `…::fromJson — messages not a list throws ArgumentError naming messages` |
| U12 | Missing `episodicMemories` key → `ArgumentError` naming `episodicMemories` | FR-005 | unit | PASSING | `…::fromJson — missing episodicMemories throws ArgumentError naming episodicMemories` |
| U13 | Element of `messages` is not a Map → `ArgumentError` naming `messages[0]` | FR-005 | unit | PASSING | `…::fromJson — malformed inner message throws ArgumentError naming messages[i]` |
| U14 | Element of `episodicMemories` fails `EpisodicMemory.fromJson` (e.g. missing `id`) → `ArgumentError` naming `episodicMemories[0]` | FR-005 | unit | PASSING | `…::fromJson — malformed inner memory throws ArgumentError naming episodicMemories[i]` |

### Purity pin (FR-007)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U15 | `appendMessages` returns a new value; the receiver's `messages.length` is unchanged | FR-007 | pin | PASSING | `…::purity — appendMessages does not mutate the receiver` |
| U16 | `addMemory` returns a new value; the receiver's `episodicMemories.length` is unchanged | FR-007 | pin | PASSING | `…::purity — addMemory does not mutate the receiver` |
| U17 | `truncate` returns a new value; the receiver's `messages.length` is unchanged | FR-007 | pin | PASSING | `…::purity — truncate does not mutate the receiver` |

## Edge cases & invariants

- Two histories with the same `messages` but reordered `episodicMemories`
  are NOT equal (order matters — `==` is structural, list-position-aware).
- An empty history is equal to another empty history (both lists empty).
- `hashCode` collision between unequal histories is statistically
  improbable (Object.hash's mixing is well-distributed); not pinned
  explicitly — the test asserts `equal hashes for equal histories`
  only (the only property that must hold).
- `fromJson` accepts a JSON map whose top-level keys include extras
  beyond `messages` and `episodicMemories` (e.g. a version tag) —
  extras are ignored, not errors (parity with `AgentMessage.fromJson`).
- `AgentMessage` subclasses have their own JSON contracts
  (`UserMessage.fromJson`, `AssistantMessage.fromJson`, etc.) —
  this spec relies on those contracts; failures propagate as
  `ArgumentError` from this layer (FR-005) wrapping the delegate's
  typed exception.

## Out of scope

- Storage optimization (deduplicating memories by id; compacting the
  messages list during `appendMessages`) — compaction spec (010).
- Equality across `AgentMessage` subclasses with non-`==` timestamps
  (timestamps are part of each subclass's existing `==` already; not
  re-tested here).
- Network-backed history sources — `fromJson` takes a JSON map; HTTP
  / S3 sources are an engine-integration concern.
- Backward compatibility with a previous (non-existent) JSON shape —
  this is the first published JSON shape for `AgentMessageHistory`.

## Verification commands

- Single test: `dart test test/llm/agent_message_history_080_test.dart -N 'spec 080 — AgentMessageHistory'`
- Full suite: `dart test`
- Analyze: `dart analyze --fatal-infos lib/src/llm/agent_message_history.dart test/llm/agent_message_history_080_test.dart`
