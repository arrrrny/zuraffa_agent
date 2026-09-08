# Test List: 032-agent-session-root

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | the returned snapshot has `currentEntryId == 'entry-1'`, `updatedAt == ts`, and the source snapshot still has `currentEntryId == null`. | AC-1 | PENDING |
| A2 | the returned snapshot's cursor is `'entry-3'` and `isHead` stays true. | AC-2 | PENDING |
| A3 | an `ArgumentError` is thrown — the cursor is never silently moved to nothing. | AC-3 | PENDING |
| A4 | the child's `currentEntryId == 'entry-3'` (fork point = current head), `parentSessionId` points at the parent, and `isBranch` is true. | AC-4 | PENDING |
| A5 | the child's cursor is the parent's `rootEntryId` — the fork point falls back to the root anchor when no entries were written. | AC-5 | PENDING |
| A6 | the child inherits the same `missionId` (the branch stays inside the mission). | AC-6 | PENDING |
| A7 | the parsed value equals the original on every field. | AC-7 | PENDING |
| A8 | those keys are absent from the JSON map — never `null`, never empty strings — and the round-trip restores them as null. | AC-8 | PENDING |
| A9 | an `ArgumentError` names the offending key (typed failure, never a silent default). | AC-9 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | The `AgentSession` root entity MUST keep its spec-exact seven-field surface — `id`, `missionId?`, `rootEntryId`, `currentEntryId?`, `parentSessionId?`, `createdAt`, `updatedAt` — with value equality, `isBranch`, and `isHead` unchanged (compile parity with the 8 existing tests). | FR-001 | PENDING |
| U2 | `appendEntry(String entryId, {DateTime? at})` MUST return a NEW snapshot with `currentEntryId == entryId` and `updatedAt == at ?? DateTime.now()`; it MUST NOT mutate the source; it MUST throw `ArgumentError` on an empty `entryId`. No tree-validity ordering is enforced (the engine owns entry ordering; the root only tracks the cursor). | FR-002 | PENDING |
| U3 | `fork({required String sessionId, DateTime? at})` MUST return a NEW child session with `id == sessionId`, `missionId` inherited, `rootEntryId` preserved, `currentEntryId == parent.currentEntryId ?? parent.rootEntryId`, `parentSessionId == parent.id`, `createdAt == updatedAt == at ?? DateTime.now()`, without mutating the source. | FR-003 | PENDING |
| U4 | `toJson()` MUST emit `id`, `rootEntryId`, `createdAt`, `updatedAt` always and `missionId`, `currentEntryId`, `parentSessionId` only when non-null (absent-never-fabricated); timestamps as ISO-8601 strings. `AgentSession.fromJson` MUST round-trip all seven fields exactly and MUST throw `ArgumentError` naming the key when a required field is missing or ill-typed. | FR-004 | PENDING |
| U5 | The clean-arch layers (`AgentSessionService.current/count`, `AgentSessionProvider`) MUST keep their existing signatures and stubs (no behavioral change — the aggregate semantics are the deliverable; wiring the provider to a store is a downstream feature). | FR-005 | PENDING |
| U6 | Transitions MUST be pure: `appendEntry`/`fork` never mutate `this` and never touch shared state (constitution-appropriate: the root stays an immutable snapshot like CircuitBreaker). | FR-006 | PENDING |

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

