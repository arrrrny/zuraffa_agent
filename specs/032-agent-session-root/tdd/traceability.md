# Traceability: 032-agent-session-root

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:38668b14db0f17b10986b941ba8709a88ad40f88aa064d4e9d09f3042e55b192
statements: 15
automated: 15
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 25 | 1. **Given** a session whose cursor is null (fresh), **When** `appendEntry('entry-1', at: ts)` is called, **Then** the returned snapshot has `currentEntryId == 'entry-1'`, `updatedAt == ts`, and the source snapshot still has `currentEntryId == null`. | A1 | automated |
| AC-2 | 27 | 2. **Given** a session whose cursor is `'entry-2'`, **When** `appendEntry('entry-3')` is called, **Then** the returned snapshot's cursor is `'entry-3'` and `isHead` stays true. | A2 | automated |
| AC-3 | 29 | 3. **Given** an empty entry id, **When** `appendEntry('')` is called, **Then** an `ArgumentError` is thrown — the cursor is never silently moved to nothing. | A3 | automated |
| AC-4 | 44 | 4. **Given** a session with cursor `'entry-3'`, **When** forked, **Then** the child's `currentEntryId == 'entry-3'` (fork point = current head), `parentSessionId` points at the parent, and `isBranch` is true. | A4 | automated |
| AC-5 | 46 | 5. **Given** a fresh session (cursor null), **When** forked, **Then** the child's cursor is the parent's `rootEntryId` — the fork point falls back to the root anchor when no entries were written. | A5 | automated |
| AC-6 | 48 | 6. **Given** a session with `missionId` set, **When** forked, **Then** the child inherits the same `missionId` (the branch stays inside the mission). | A6 | automated |
| AC-7 | 63 | 7. **Given** a fully-populated session (id, missionId, rootEntryId, currentEntryId, parentSessionId, createdAt, updatedAt), **When** serialized and parsed back, **Then** the parsed value equals the original on every field. | A7 | automated |
| AC-8 | 65 | 8. **Given** a minimal session (null missionId/currentEntryId/parentSessionId), **When** serialized, **Then** those keys are absent from the JSON map — never `null`, never empty strings — and the round-trip restores them as null. | A8 | automated |
| AC-9 | 67 | 9. **Given** a JSON map missing `id`, `rootEntryId`, `createdAt` or `updatedAt`, **When** parsed, **Then** an `ArgumentError` names the offending key (typed failure, never a silent default). | A9 | automated |
| FR-001 | 82 | - **FR-001**: The `AgentSession` root entity MUST keep its spec-exact seven-field surface — `id`, `missionId?`, `rootEntryId`, `currentEntryId?`, `parentSessionId?`, `createdAt`, `updatedAt` — with value equality, `isBranch`, and `isHead` unchanged (compile parity with the 8 existing tests). | U1 | automated |
| FR-002 | 83 | - **FR-002**: `appendEntry(String entryId, {DateTime? at})` MUST return a NEW snapshot with `currentEntryId == entryId` and `updatedAt == at ?? DateTime.now()`; it MUST NOT mutate the source; it MUST throw `ArgumentError` on an empty `entryId`. No tree-validity ordering is enforced (the engine owns entry ordering; the root only tracks the cursor). | U2 | automated |
| FR-003 | 84 | - **FR-003**: `fork({required String sessionId, DateTime? at})` MUST return a NEW child session with `id == sessionId`, `missionId` inherited, `rootEntryId` preserved, `currentEntryId == parent.currentEntryId ?? parent.rootEntryId`, `parentSessionId == parent.id`, `createdAt == updatedAt == at ?? DateTime.now()`, without mutating the source. | U3 | automated |
| FR-004 | 85 | - **FR-004**: `toJson()` MUST emit `id`, `rootEntryId`, `createdAt`, `updatedAt` always and `missionId`, `currentEntryId`, `parentSessionId` only when non-null (absent-never-fabricated); timestamps as ISO-8601 strings. `AgentSession.fromJson` MUST round-trip all seven fields exactly and MUST throw `ArgumentError` naming the key when a required field is missing or ill-typed. | U4 | automated |
| FR-005 | 86 | - **FR-005**: The clean-arch layers (`AgentSessionService.current/count`, `AgentSessionProvider`) MUST keep their existing signatures and stubs (no behavioral change — the aggregate semantics are the deliverable; wiring the provider to a store is a downstream feature). | U5 | automated |
| FR-006 | 87 | - **FR-006**: Transitions MUST be pure: `appendEntry`/`fork` never mutate `this` and never touch shared state (constitution-appropriate: the root stays an immutable snapshot like CircuitBreaker). | U6 | automated |

