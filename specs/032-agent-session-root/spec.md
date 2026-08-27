# Feature Specification: AgentSession root entity (R2 sessions) — aggregate transitions + persistence contract

**Feature Branch**: `feat/specs-032-033-034-035` (spec dir: `032-agent-session-root`)

**Created**: 2026-08-24 | **Refined**: 2026-08-27 via /speckit.specify (drift remediation)

**Status**: Approved

**Input**: Verbatim task spec — "032-agent-session-root — the top-level agent session aggregate (root of messages, branches, tree entries; persistence contract). Existing: lib/src/session_storage*.dart, lib/src/jsonl_session_storage.dart, lib/src/hive_session_store.dart, lib/src/data/providers/agent_session/*, lib/src/domain/services/agent_session_service.dart, lib/src/domain/entities/agent_session. Spec + tests for the session-root aggregate behavior."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The engine advances the session cursor by appending entries (Priority: P1)

As the engine loop, when a turn/tool/usage entry is appended to the session tree, I advance the session's `currentEntryId` cursor to the new entry and stamp `updatedAt`, receiving a new immutable snapshot — the append never mutates the snapshot a consumer may still be reading.

**Why this priority**: The cursor advance is the single most frequent write in the aggregate (every entry, every turn); the entity's own scaffold doc describes the cursor as "mutable... the engine initialises it to `rootEntryId` on the first append", but the scaffold ships NO transition method — the documented behavior has no API. This is the drift this feature remediates.

**Independent Test**: `AgentSession.appendEntry(entryId, at: ts)` returns a snapshot with `currentEntryId == entryId` and `updatedAt == ts`; the source snapshot is unchanged.

**Acceptance Scenarios**:

1. **Given** a session whose cursor is null (fresh), **When** `appendEntry('entry-1', at: ts)` is called, **Then** the returned snapshot has `currentEntryId == 'entry-1'`, `updatedAt == ts`, and the source snapshot still has `currentEntryId == null`.
2. **Given** a session whose cursor is `'entry-2'`, **When** `appendEntry('entry-3')` is called, **Then** the returned snapshot's cursor is `'entry-3'` and `isHead` stays true.
3. **Given** an empty entry id, **When** `appendEntry('')` is called, **Then** an `ArgumentError` is thrown — the cursor is never silently moved to nothing.

---

### User Story 2 - Branching forks the session at the current head (Priority: P2)

As the engine (R2.2 "branch/fork/resume first-class"), when a mission forks, I derive a child session that links to its parent via `parentSessionId`, keeps the same entry-tree `rootEntryId`, and starts its cursor at the fork point (the parent's current head), so the branch grows from the same tree without copying it.

**Why this priority**: Branching is the second half of the R2.1 data model ("tree-of-entries, branching"); the scaffold exposes `isBranch` as a read but no way to produce a branch — the write-side of the documented model is missing.

**Independent Test**: `session.fork(sessionId: 'sess-2', at: ts)` returns a session with `parentSessionId == session.id`, `rootEntryId == session.rootEntryId`, `currentEntryId == session.currentEntryId`, `isBranch == true`; the source session is unchanged and stays a non-branch.

**Acceptance Scenarios**:

1. **Given** a session with cursor `'entry-3'`, **When** forked, **Then** the child's `currentEntryId == 'entry-3'` (fork point = current head), `parentSessionId` points at the parent, and `isBranch` is true.
2. **Given** a fresh session (cursor null), **When** forked, **Then** the child's cursor is the parent's `rootEntryId` — the fork point falls back to the root anchor when no entries were written.
3. **Given** a session with `missionId` set, **When** forked, **Then** the child inherits the same `missionId` (the branch stays inside the mission).

---

### User Story 3 - The session root crosses the persistence boundary (Priority: P1)

As the persistence layer (JSONL session storage / Hive session store / session-tree replay), I serialize the session root to JSON and parse it back without losing the cursor, the branch link, or the timestamps, so a session survives process restarts and store round-trips.

**Why this priority**: The task input names the persistence contract explicitly; every existing store (jsonl_session_storage, hive_session_store) persists entries — without a serializable root, the tree's anchor and cursor have no wire shape. Precedent: spec 031 landed `toJson`/`fromJson` for ToolResult for exactly this boundary.

**Independent Test**: `AgentSession.fromJson(session.toJson()) == session` for a fully-populated session (all seven fields); null optionals serialize absent, never fabricated.

**Acceptance Scenarios**:

1. **Given** a fully-populated session (id, missionId, rootEntryId, currentEntryId, parentSessionId, createdAt, updatedAt), **When** serialized and parsed back, **Then** the parsed value equals the original on every field.
2. **Given** a minimal session (null missionId/currentEntryId/parentSessionId), **When** serialized, **Then** those keys are absent from the JSON map — never `null`, never empty strings — and the round-trip restores them as null.
3. **Given** a JSON map missing `id`, `rootEntryId`, `createdAt` or `updatedAt`, **When** parsed, **Then** an `ArgumentError` names the offending key (typed failure, never a silent default).

### Edge Cases

- Empty `entryId` on `appendEntry` → `ArgumentError` (AC US1-3).
- Fork of a fresh (cursor-null) session → fork point falls back to `rootEntryId` (AC US2-2).
- Timestamps serialize as ISO-8601; tests use `DateTime.utc` values that round-trip exactly. A non-UTC `DateTime` normalizes to the same instant in UTC — the store keeps instants, not zones.
- `fromJson` with a non-string `id`/`rootEntryId` → `ArgumentError` (shape violations are typed errors).
- JSONL/Hive stores are NOT rewired in this feature — the value object ships the contract they will consume (FR-007 boundary).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The `AgentSession` root entity MUST keep its spec-exact seven-field surface — `id`, `missionId?`, `rootEntryId`, `currentEntryId?`, `parentSessionId?`, `createdAt`, `updatedAt` — with value equality, `isBranch`, and `isHead` unchanged (compile parity with the 8 existing tests).
- **FR-002**: `appendEntry(String entryId, {DateTime? at})` MUST return a NEW snapshot with `currentEntryId == entryId` and `updatedAt == at ?? DateTime.now()`; it MUST NOT mutate the source; it MUST throw `ArgumentError` on an empty `entryId`. No tree-validity ordering is enforced (the engine owns entry ordering; the root only tracks the cursor).
- **FR-003**: `fork({required String sessionId, DateTime? at})` MUST return a NEW child session with `id == sessionId`, `missionId` inherited, `rootEntryId` preserved, `currentEntryId == parent.currentEntryId ?? parent.rootEntryId`, `parentSessionId == parent.id`, `createdAt == updatedAt == at ?? DateTime.now()`, without mutating the source.
- **FR-004**: `toJson()` MUST emit `id`, `rootEntryId`, `createdAt`, `updatedAt` always and `missionId`, `currentEntryId`, `parentSessionId` only when non-null (absent-never-fabricated); timestamps as ISO-8601 strings. `AgentSession.fromJson` MUST round-trip all seven fields exactly and MUST throw `ArgumentError` naming the key when a required field is missing or ill-typed.
- **FR-005**: The clean-arch layers (`AgentSessionService.current/count`, `AgentSessionProvider`) MUST keep their existing signatures and stubs (no behavioral change — the aggregate semantics are the deliverable; wiring the provider to a store is a downstream feature).
- **FR-006**: Transitions MUST be pure: `appendEntry`/`fork` never mutate `this` and never touch shared state (constitution-appropriate: the root stays an immutable snapshot like CircuitBreaker).

### Key Entities *(include if feature involves data)*

- **AgentSession** (root entity, existing scaffold): seven-field surface + NEW pure transitions `appendEntry`/`fork` + NEW `toJson`/`fromJson` (persistence contract).
- **AgentSessionService / AgentSessionProvider** (existing interfaces): unchanged surfaces; compile parity pinned by the existing 8 tests.
- Downstream consumers (NOT modified here): `jsonl_session_storage.dart`, `hive_session_store.dart`, `session_storage_impl.dart` — the shape FR-004 defines is the contract they consume when their own specs land.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `appendEntry` advances the cursor, stamps `updatedAt`, leaves the source unchanged, and rejects empty ids (AC US1-1..3).
- **SC-002**: `fork` produces a branch linked at the current head, falling back to the root anchor for fresh sessions, inheriting missionId (AC US2-1..3).
- **SC-003**: fully-populated sessions round-trip through JSON field-exactly (AC US3-1).
- **SC-004**: minimal sessions serialize with absent optionals and round-trip them back to null (AC US3-2).
- **SC-005**: malformed JSON fails with a typed `ArgumentError` naming the key (AC US3-3, edge-4).
- **SC-006**: `dart analyze --fatal-infos` zero new issues; full `dart test` green (baseline 597 passed); the 8 pre-existing provider tests pass unchanged (FR-001, FR-005).

## Assumptions

- The transition methods are additive (scaffold surface untouched), mirroring the CircuitBreaker precedent (`recordFailure`/`recordSuccess`/`tryHalfOpen` are pure snapshot transitions) and the spec-031 refinement precedent (additive semantics on a hand-curated value object).
- The root stores entry IDS only — the engine owns tree validity (no parent/child ordering checks in `appendEntry`; documented in FR-002).
- Timestamps in JSON are ISO-8601 strings; zone normalization to UTC is accepted behavior for non-UTC values (the stores keep instants).
- The provider/service layers stay stubs in this feature (FR-005): wiring them to a store is a separate feature; the existing compile-parity and stub tests keep passing unchanged.
- The scaffold's `hashCode` (all-scalar fields through `Object.hash`) already satisfies the ==/hashCode contract — no hash remediation needed here (unlike spec 034, where a Map field breaks the contract).
