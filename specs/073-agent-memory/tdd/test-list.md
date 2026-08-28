# Test List: Agent memory — three layers

---
feature: 073-agent-memory
loop: outside-in
profile: .specify/memory/tdd-profile.md # referenced by sibling 023; file absent at HEAD — 023 artifact as de-facto rubric + constitution.md Principles II/V/X
spec_criteria: 10 # FR-001..FR-010 in spec.md
planned_at: fec7889 # master
updated_at: HEAD
suite_baseline: green # 915 passed / 2 skipped at fec7889
---

## Outer loop: acceptance behaviors

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| A1  | The three-layer story end-to-end: remember a long-term fact + a session note about it, link them `supports`, recall finds BOTH with correct layer attribution, promote the session note, recall still finds it (now long-term), the link survives | FR-006, FR-007, FR-008, FR-009 | example | PASSING | `test/engine/agent_memory_test.dart::spec 073 — AgentMemorySystem::three-layer story: remember, link, recall, promote` |
| A2  | Recall ranking: salience desc then createdAt desc across BOTH layers interleaved (long-term low-salience vs session high-salience → session first) | FR-007 | example | PASSING | `…::recall ranks by salience then recency across both layers` |
| A3  | Recall limit caps the merged result; empty query returns empty (no accidental match-all) | FR-007 | example | PASSING | `…::recall honors the limit and rejects empty queries` |
| A4  | Graph integrity at the facade: link with either endpoint missing → ArgumentError; self-link → ArgumentError; re-linking the same from/to/type replaces (no throw) | FR-005, FR-008 | example | PASSING | `…::link validates endpoints and stays idempotent` |
| A5  | Promote semantics: unknown id → ArgumentError; long-term id → ArgumentError; happy path removes from session store, preserves id/content/createdAt, lands in long-term | FR-009 | example | PASSING | `…::promote moves a session memory into long-term` |
| A6  | Session evaporate: forgetSession drops the session's records; dangling links resolve with null record in `linked` | FR-003, FR-008 | example | PASSING | `…::forgetSession evaporates session memory and leaves honest dangling links` |
| A7  | Gates: `dart analyze --fatal-infos` exit 0; full `dart test` green (baseline 915/2 + new) | FR-010 | gate | PASSING | gates at branch HEAD (counts in verification.md) |

## Inner loop: unit behaviors

### `lib/src/engine/agent_memory.dart` (new)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U1  | `MemoryRecord` / `MemorySource` / `MemoryLink` / `RecallHit` value semantics (==, hashCode, toString); salience bounds; empty content; source all-null each validated | FR-001, FR-004 | example | PASSING | `…::value objects carry house semantics and validation` |
| U2  | Long-term store: same-id replace keeps position; search case-insensitive substring ranked salience/createdAt; byTag exact; latest(n); unmodifiable views | FR-002 | example | PASSING | `…::LongTermMemoryStore replaces, ranks, and filters` |
| U3  | Session store: records scoped per session (same id in two sessions is a replace within the second… no — id is globally unique, second insert replaces the FIRST occurrence and rescopes it); forSession insertion order; byId across sessions | FR-003 | example | PASSING | `…::SessionMemoryStore scopes by session with global id uniqueness` |
| U4  | Graph standalone: neighborsOf includes incoming AND outgoing (outgoing flag correct); contradictions(); linksOf(type); direction is meaningful (a supports b ≠ b supports a — different links) | FR-004, FR-005 | example | PASSING | `…::MemoryGraph traverses both directions and filters by type` |

## Invariants and edge cases

- Layer attribution: every RecallHit carries the layer its record came from; interleaved ranking never partitions by layer (A2).
- Promote preserves identity: id, content, createdAt identical before/after (A5).
- Dangling links are honest: `linked` returns the link with null record rather than hiding or crashing (A6).
- Empty query: recall returns empty — no match-all footgun (A3).
- Graph direction: from/to are NOT interchangeable — the pair (from,to,type) is the identity; (to,from,type) is a different, legitimate link (U4).
- Session store id uniqueness: an id moves with its record — remembering the same id under a different session relocates it (U3).

## Mutation plan (deliberate, one at a time, cp-restored)

| id  | mutant | killed by |
| --- | ------ | --------- |
| M1  | recall sorted by insertion order (salience ranking dropped) | A2 (session high-salience must outrank long-term low-salience) |
| M2  | recall searches long-term store only | A1/A2 (session hits vanish) |
| M3  | promote copies to long-term but does NOT remove from session store | A5 (forSession must be empty after promote) |
| M4  | neighborsOf returns outgoing links only | U4 (incoming link invisible) |
| M5  | duplicate (from,to,type) link throws instead of replacing | A4 (re-link must not throw) |
