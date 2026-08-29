# Feature Specification: R1 — Agent Message History (context assembly & pure transforms)

**Branch**: `080-agent-message-history` (off master `29b7fef`) | **Date**: 2026-08-29

## Summary

The engine needs a value object that holds the conversation context
assembled for the model: the active (uncompressed) message list plus
the episodic memory list built up by earlier compressions. The repo
already ships `lib/src/llm/agent_message_history.dart` with
`AgentMessageHistory` — a hand-curated value object that:

- composes `List<AgentMessage> messages` + `List<EpisodicMemory> episodicMemories`;
- exposes the three pure transforms the engine calls between turns:
  `appendMessages(Iterable<AgentMessage>)`,
  `addMemory(EpisodicMemory)`,
  `truncate(int keep)` (last-N retention; never drops memories);
- exposes `memorySummaries` (insertion-order summaries for context-building);
- refuses negative `keep` with `ArgumentError`.

This spec closes the gaps the R1 engine-core contract (issue #2)
requires but the current file is missing:

1. **No value equality.** `AgentMessageHistory` has no `==` / `hashCode`.
   The engine compares histories (engine loop's "did the context
   change between turns?" check; tests asserting a transformation
   produced the expected state) using identity today — fragile and
   wrong. The spec requires full-field equality: two histories with
   equal `messages` and equal `episodicMemories` are equal.
2. **No JSON contract.** `AgentMessageHistory` has no `toJson` /
   `fromJson`. The R1 brief says "Define equality and toJson/fromJson
   as needed for engine consumption" — engine consumption includes
   the session-persistence boundary (the JSONL session store, spec
   010's `EpisodicMemory.fromJson`, the replay/cassette pipeline in
   `lib/src/eval/`). Without a JSON contract, a history cannot
   survive the store boundary between turns.
3. **`truncate`'s "never drops memories" guarantee is unpinned.** The
   doc comment says "Episodic memories ride along untouched: truncation
   never loses a memory summary." The spec-041 test file pins this
   with three truncation shapes (last-N, 0, identity) but does NOT
   pin the equality contract (a truncated history's `episodicMemories`
   field must be the SAME list reference, not a defensive copy — or
   vice versa). This spec pins the semantic: truncation returns a
   new `AgentMessageHistory` whose `episodicMemories` field equals
   (by `==`) the receiver's — proving no memory was dropped, added,
   or reordered.

This spec closes all three. The file is edited in place; the public
API grows additively (`==`, `hashCode`, `toJson`, `fromJson`); the
existing pure transforms are unchanged in signature and behavior.

**Out of scope, documented deviation**: storage optimization (e.g.
deduplicating memories by id, compacting the messages list during
`appendMessages`) — the engine loop's compaction spec (010) owns
that. This value object is just the context carrier; transforms are
pure and structural.

## Files

- `lib/src/llm/agent_message_history.dart` — EDIT (additive):
  - `AgentMessageHistory.==` (new — full-field equality over
    `messages` and `episodicMemories`).
  - `AgentMessageHistory.hashCode` (new — `Object.hash` over the
    two lists via `Object.hashAll`).
  - `AgentMessageHistory.toJson()` (new — `{messages: [...],
    episodicMemories: [...]}` shape).
  - `AgentMessageHistory.fromJson(Map<String, dynamic>)` factory
    (new — typed `ArgumentError` on malformed input, parity with
    `EpisodicMemory.fromJson` and `SteeringMessage.fromJson`).
- `test/llm/agent_message_history_080_test.dart` — NEW: covers
  equality, JSON round-trip, truncation's "memories preserved" pin
  via equality, and malformed-input error paths. Lives in its own
  file so spec-010's `agent_message_history_test.dart` (U1) and
  spec-041's `agent_message_history_041_test.dart` (U4–U8) stay
  byte-identical (their cycles' records depend on it).

## User scenarios

### US1 — Two histories with the same messages + memories are equal (P1)

As an engine-loop author, I compare two `AgentMessageHistory` values
with `==` and they are equal iff both `messages` lists are
element-wise equal AND both `episodicMemories` lists are
element-wise equal. `hashCode` agrees with `==`. This lets me assert
"the context did not change between turns" with `expect(history1,
equals(history2))`.

**Independent test**: two histories built from the same message +
memory lists (different list instances) compare equal; mutating one
list breaks equality; `hashCode` matches.

### US2 — History round-trips through JSON (P1)

As an engine-integration author, I serialize a history with `toJson`
and parse it back with `fromJson`; the result equals the original
(lossless round-trip). The JSON shape is `{messages: [...],
episodicMemories: [...]}` — the same shape `EpisodicMemory.toJson`
already produces for its own `messages` field, so the contract is
internally consistent.

**Independent test**: a history with two messages + one memory →
`toJson` → `fromJson` → equals the original (using `==` from US1).

### US3 — truncate preserves memories — proven by equality (P2)

As an engine-core maintainer, the "truncation never drops a memory"
guarantee is pinned not just by "the list has the same length" but
by equality: `history.truncate(N).episodicMemories == history.episodicMemories`.
This is a stronger pin — it catches reordering, duplication, or
subtle replacement of a memory by an equal-but-different instance.

**Independent test**: a history with three messages + two memories;
`truncate(2)` returns a history whose `episodicMemories` equals the
original's via `==`.

### US4 — Malformed JSON throws typed ArgumentError (P2)

As an engine-integration author, parsing a JSON map that is missing
`messages` or `episodicMemories`, has them as the wrong type (not a
list), or carries a malformed inner `AgentMessage` (unknown role)
surfaces as a typed `ArgumentError` naming the offending key —
parity with `EpisodicMemory.fromJson` and `SteeringMessage.fromJson`.

**Independent test**: each malformed-input variant (missing
`messages`, missing `episodicMemories`, `messages` not a list,
malformed inner `AgentMessage`) throws `ArgumentError` naming the
key.

## Requirements

### Functional requirements

- **FR-001**: `AgentMessageHistory.==` MUST return `true` iff both
  `messages` lists are element-wise equal (using each `AgentMessage`
  subclass's existing `==`) AND both `episodicMemories` lists are
  element-wise equal (using `EpisodicMemory.==`); `false` otherwise.
  Identity (`identical`) short-circuits to `true`.
- **FR-002**: `AgentMessageHistory.hashCode` MUST agree with `==` —
  two equal histories produce equal hashCodes. Implementation via
  `Object.hash(Object.hashAll(messages), Object.hashAll(episodicMemories))`.
- **FR-003**: `AgentMessageHistory.toJson()` MUST return a
  `Map<String, dynamic>` of shape `{messages: [for each m in messages: m.toJson()], episodicMemories: [for each em in episodicMemories: em.toJson()]}`.
  An empty history → `{messages: [], episodicMemories: []}`.
- **FR-004**: `AgentMessageHistory.fromJson(Map<String, dynamic> json)`
  MUST produce a history equal (by FR-001) to the original that was
  serialized with `toJson` — lossless round-trip.
- **FR-005**: `AgentMessageHistory.fromJson` MUST throw `ArgumentError`
  naming the offending key when:
  - `messages` is missing or not a `List`;
  - `episodicMemories` is missing or not a `List`;
  - any element of `messages` is not a `Map<String, dynamic>` or
    fails `AgentMessage.fromJson` (typed error from the delegate
    propagates — `ArgumentError` is added at this layer naming the
    index of the offending message);
  - any element of `episodicMemories` is not a `Map<String, dynamic>`
    or fails `EpisodicMemory.fromJson` (typed error from the delegate
    propagates — `ArgumentError` is added at this layer naming the
    index of the offending memory).
- **FR-006**: `truncate(int keep)` MUST return a new
  `AgentMessageHistory` whose `episodicMemories` field equals
  (by `==`, FR-001) the receiver's — no memory dropped, added, or
  reordered. (Already behaviorally true; this spec pins it via
  equality, not just length.)
- **FR-007**: existing pure transforms (`appendMessages`, `addMemory`,
  `truncate`) MUST remain pure: return a new value, never mutate the
  receiver. (Already behaviorally true; pinned by an assertion test.)
- **FR-008**: existing constructor + `memorySummaries` MUST remain
  unchanged — no signature change, no behavior change.
- **FR-009** (gates): `dart analyze --fatal-infos` exit 0 on the
  changed files; full `dart test` green (baseline 1089/2 + new).

### Key entities

- `AgentMessageHistory` — value object: `messages`, `episodicMemories`,
  `memorySummaries` getter, `appendMessages`, `addMemory`, `truncate`,
  **NEW**: `==`, `hashCode`, `toJson`, `fromJson`. Plain Dart class
  (constitution IX exemption — same precedent as `EpisodicMemory`
  itself, `SteeringMessage`, `AgentSession` PR #50, `ToolResult` PR
  #49, `StopPolicy` PR #47 — the file already ships hand-curated
  without `@Zorphy`).
- `AgentMessage` — sealed class (in `lib/src/types.dart`); existing
  `toJson`/`fromJson` factory + per-subclass equality. Unchanged.
- `EpisodicMemory` — value object (in
  `lib/src/domain/entities/episodic_memory/`); existing
  `toJson`/`fromJson`/equality. Unchanged.

## Success criteria

- **SC-001**: Two histories built from equal (but distinct
  instances) message + memory lists compare equal via `==`; mutating
  one breaks equality; `hashCode` agrees (US1 / FR-001 / FR-002).
- **SC-002**: A history with N messages + M memories round-trips
  through `toJson` → `fromJson` to an equal history (US2 /
  FR-003 / FR-004).
- **SC-003**: `truncate(N)` returns a history whose `episodicMemories`
  field equals (by `==`) the receiver's (US3 / FR-006).
- **SC-004**: Every malformed-input variant (missing keys, wrong
  types, malformed inner message/memory) throws `ArgumentError`
  naming the offending key (US4 / FR-005).
- **SC-005**: Existing transforms (`appendMessages`, `addMemory`,
  `truncate`) remain pure — the receiver is unchanged after the call
  (FR-007).
- **SC-006**: Every pinned behavior (FR-001..FR-008) is guarded by a
  test that a deliberate mutant kills (mutation evidence in
  `tdd/verification.md`).

## Dependencies

- Builds on: master `29b7fef` — `lib/src/llm/agent_message_history.dart`
  already exists (hand-curated; this spec adds equality + JSON contract).
- Builds on: `lib/src/types.dart` — `AgentMessage` sealed class with
  per-subclass `toJson`/`fromJson`/equality already in place.
- Builds on: `lib/src/domain/entities/episodic_memory/episodic_memory.dart`
  — `EpisodicMemory` with `toJson`/`fromJson`/equality already in
  place.
- Independent of: every other spec in flight (engine event bus,
  memory arc, request/response, skill system) — different file,
  different tests. Spec 079 (skill system) lands on master separately;
  this spec branches from `29b7fef` so the two are independent.
