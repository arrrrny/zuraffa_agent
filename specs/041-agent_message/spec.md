# Feature Specification: AgentMessage (multimodal parts) + history

**Feature Branch**: `041-agent_message`

**Created**: 2026-08-24 | **Refined**: 2026-08-27 via /speckit.specify (drift remediation — role validation, parts value-equality fix, history truncate added; criteria made measurable)

**Status**: Approved

**Input**: Verbatim task spec — "041-agent_message — agent message value object + history. Existing: lib/src/llm/agent_message_history.dart, lib/src/data/providers/agent_message/agent_message_provider.dart, lib/src/domain/services/agent_message_service.dart, lib/src/domain/entities/agent_message/agent_message.dart. Spec + tests for the message entity semantics (roles, content parts, history append/truncate)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A message is a validated multimodal value (Priority: P1)

As the engine assembling turns, I build `AgentMessage(id, role, parts)` values where `id` and `role` are non-empty (a message without identity or role is unaddressable in the session tree), and `parts` is a list of content parts (text blocks, image refs, any object) whose equality is VALUE equality: two messages with distinct-but-equal part lists are the same message.

**Why this priority**: The shipped entity compares `parts` with Dart's `List ==` — identity for lists — so two field-identical messages built independently compare UNEQUAL whenever their part lists are distinct instances. That silently breaks dedup, replay comparison, and any set/map keyed by messages. Equality is the entity's contract; fixing it (plus identity validation) is the deliverable.

**Independent Test**: Empty `id` or empty `role` throws `ArgumentError` naming the field; two messages with independently built `['hello']` parts lists are `==` and hash equally; a single-field difference breaks equality.

**Acceptance Scenarios**:

1. **Given** a message with empty `id` or empty `role`, **When** constructed, **Then** `ArgumentError` is thrown naming the field.
2. **Given** two messages equal in id/role with distinct-but-equal `parts` list instances, **When** compared, **Then** they are `==` and share `hashCode` (the bug the shipped `parts == other.parts` identity comparison causes).
3. **Given** two messages differing in id, role, or parts content, **Then** they are unequal.

---

### User Story 2 - History appends messages and truncates to a budget (Priority: P2)

As the context builder (spec 002/009 lineage), I append messages to the active history and, when the context window overflows, I truncate the ACTIVE messages to the most recent N while the episodic-memory ledger rides along untouched — truncation never loses a memory summary.

**Why this priority**: append exists but is unpinned; truncate does not exist and is the other half of the context-window lifecycle the engine loop needs.

**Independent Test**: `appendMessages` extends messages oldest-first and leaves memories untouched; `truncate(n)` keeps the LAST n messages (0 → empty), preserves `episodicMemories` and `memorySummaries` exactly, throws on negative n, and is a no-op-shape copy when n >= length.

**Acceptance Scenarios**:

1. **Given** a history of 3 messages, **When** `truncate(2)`, **Then** the result keeps messages 2..3 (the most recent), `episodicMemories` is unchanged, and `memorySummaries` is unchanged.
2. **Given** `truncate(0)`, **Then** messages is empty and memories survive; **given** `truncate(-1)`, **Then** `ArgumentError`.
3. **Given** `truncate(n)` with n >= length, **Then** the result equals a history with the same messages/memories (content-equal, not necessarily identical).
4. **Given** a history, **When** `appendMessages([m])`, **Then** messages grow oldest-first at the end and memories are unchanged (pin of shipped behavior).

---

### User Story 3 - Role dispatch over the wire stays pinned (Priority: P3)

As the persistence layer, messages cross the boundary as role-tagged JSON; the sealed hierarchy's role dispatch (user/assistant/toolResult/custom) and content-part deserialization are already pinned by `types_test.dart` — this feature keeps them green and changes none of them.

**Why this priority**: The sealed hierarchy is the wire-facing model; it already has thorough coverage. Pinning = not regressing.

**Independent Test**: The 40+ pre-existing `types_test.dart` assertions (roles, parts, round-trips, unknown-role rejection) stay green unchanged.

**Acceptance Scenarios**:

1. **Given** the untouched sealed hierarchy, **When** the suite runs, **Then** all pre-existing types tests pass (pinned; no new code).

### Edge Cases

- Empty `parts` list? → Valid (a role-only message can exist; the hierarchy's UserMessage.fromJson with empty content produces exactly that).
- Parts containing mixed types (String, Map)? → Equality is element-wise and DEEP for embedded Maps/Lists (same discipline as `UiTreePayload._deepEq` — refined during the U2 cycle after the first implementation's shallow comparison failed the mixed-parts test); other object types compare by their own `==`.
- `truncate` on a history with no memories? → Same semantics; memories list stays empty.
- Does `truncate` mutate the receiver? → No — `AgentMessageHistory` is immutable; every operation returns a new value (pinned).
- Duplicate message ids? → Allowed at the entity level (dedup is the session tree's concern).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `AgentMessage` MUST reject with `ArgumentError` an empty `id` or empty `role` (message naming the field); `parts` may be any (including empty) list.
- **FR-002**: `AgentMessage` equality MUST compare `id`, `role`, and `parts` with ELEMENT-WISE list equality (distinct-but-equal instances compare equal); `hashCode` MUST fold `parts` content (e.g. `Object.hashAll`) so equal messages hash equally.
- **FR-003**: `AgentMessageHistory.appendMessages` keeps its shipped semantics (new messages appended oldest-first; memories untouched) — pinned, not changed.
- **FR-004**: `AgentMessageHistory.truncate(int keep)` MUST return a new history whose `messages` are the LAST `keep` messages (`0` → empty), with `episodicMemories` unchanged; `keep < 0` MUST throw `ArgumentError`; `keep >= length` MUST return a content-equal history.
- **FR-005**: `addMemory` keeps its shipped semantics (insertion-order append of an episodic memory) — pinned, not changed.
- **FR-006**: The sealed `AgentMessage` hierarchy in `lib/src/types.dart` (roles, content parts, JSON round-trips) MUST remain byte-identical — its coverage stays in `types_test.dart` (pinned).
- **FR-007**: The clean-arch layers (`AgentMessageService.current/count`, `AgentMessageProvider`) MUST keep their existing signatures and stub behavior; no behavioral change in this feature.

### Key Entities *(include if feature involves data)*

- **AgentMessage** (domain value object, existing): 3 fields; this feature adds validation (FR-001) and fixes parts equality/hashCode (FR-002).
- **AgentMessageHistory** (llm value object, existing): + `truncate` (FR-004); append/addMemory pinned (FR-003/005).
- **AgentMessageService / AgentMessageProvider** (existing interfaces): unchanged; pinned by the 3 clean-arch tests.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Empty id/role construction throws (AC US1-1).
- **SC-002**: Distinct-instance equal-parts messages are `==` and hash equally (AC US1-2); single-field differences are unequal (AC US1-3).
- **SC-003**: truncate keeps the last N, preserves memories, throws on negative, no-ops-shape at n >= length (AC US2-1..3).
- **SC-004**: appendMessages/addMemory pinned green (AC US2-4); all pre-existing tests (incl. types_test.dart role coverage and the 5-test provider suite) pass unchanged (FR-003/005/006/007).
- **SC-005**: `dart analyze` zero new findings vs the 5-issue baseline; full `dart test` green.

## Assumptions

- The domain `AgentMessage` (id/role/parts) and the sealed hierarchy in `types.dart` coexist by design: the entity is the registry/persistence projection, the sealed hierarchy is the wire model (its const constructor and timestamp default are untouched).
- `truncate` is last-N retention (oldest dropped) — the standard context-window eviction order; compaction/summarization before truncation is spec 009's concern.
- Element-wise parts equality uses each part's own `==`; parts without value equality compare by identity — documented, not fixed here.
