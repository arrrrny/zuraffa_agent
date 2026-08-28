# Feature Specification: Agent memory — three layers

**Branch**: `feat/spec-073-agent-memory` (off master `fec7889`) | **Date**: 2026-08-29

## Summary

A three-layer memory architecture for the agent, unifying what exists and
building what is missing:

- **Layer 1 — long-term memory** (`LongTermMemoryStore`): durable,
  cross-session facts, knowledge, and preferences. Survives sessions;
  the substrate for agent personality and accumulated expertise.
  Nothing like this exists today — specs 009/010 delivered episodic
  memory, which is a *compression mechanism* (slices of one
  conversation), not curated long-term knowledge.
- **Layer 2 — session memory** (`SessionMemoryStore`): working memory
  scoped to a session id — notes, learnings, and outcomes the agent
  records while it works. Evaporates with the session unless
  **promoted** to long-term (the explicit bridge between layers).
- **Layer 3 — cross-referenced memory** (`MemoryGraph`): typed, directed
  links between ANY two memory records across both layers —
  `supports`, `contradicts`, `supersedes`, `derivedFrom`, `relatesTo` —
  with bidirectional traversal and contradiction surfacing. Memories
  stop being flat rows and become a knowledge graph.

`AgentMemorySystem` is the facade that composes the three layers:
`remember` routes by scope, `recall` searches all layers and returns
layer-attributed hits, `link`/`linked` manage the graph, `promote`
moves a session memory into long-term.

Design stance: this spec composes with the episodic-memory subsystem
(009/010) — it neither replaces nor modifies it. EpisodicMemory stays
the compression snapshot mechanism; these layers are the curated memory
the agent (and spec 074's tools) read and write deliberately. All state
is in-memory here; persistence follows the 010 precedent in a later
spec. Value objects follow the house pattern (plain Dart, `==` /
`hashCode` / `toString`, no codegen).

## Files

- `lib/src/engine/agent_memory.dart` — NEW: `MemoryRecord`,
  `MemorySource`, `MemoryLinkType`, `MemoryLink`, `MemoryLayer`,
  `RecallHit`, `LongTermMemoryStore`, `SessionMemoryStore`,
  `MemoryGraph`, `AgentMemorySystem`.
- `test/engine/agent_memory_test.dart` — NEW: unit + behavior tests.
- `specs/073-agent-memory/{spec,plan,tasks}.md` +
  `tdd/{test-list,verification}.md`.

## FRs

- **FR-001** — `MemoryRecord` (house value semantics): `id`, `content`
  (non-empty — `ArgumentError` on empty/whitespace), `tags`
  (unordered set, case preserved), `source` (`MemorySource`:
  `sessionId?`, `missionId?`, `agentName?` — at least one must be set),
  `createdAt` (UTC), `salience` (`0.0..1.0`, default `0.5` — out of
  range throws `ArgumentError`).
- **FR-002** — Long-term store: `remember(MemoryRecord)` (same-id
  replaces, insertion order kept), `byId`, `search(String)` —
  case-insensitive substring over content ordered by salience
  (descending), then createdAt (descending), `byTag(String)` — exact
  match, `latest(int)` — most recent by createdAt. Unmodifiable views
  out.
- **FR-003** — Session store: `remember(sessionId, record)` (a record
  belongs to exactly one session; same-id replaces within it),
  `forSession(sessionId)` (insertion order), `forgetSession(sessionId)`
  (drops the session's records — the evaporate path), `byId` (searches
  all sessions; a record id is globally unique across the store).
- **FR-004** — `MemoryLinkType`: `supports`, `contradicts`,
  `supersedes`, `derivedFrom`, `relatesTo`. `MemoryLink`:
  `fromRecordId`, `toRecordId`, `type`, `createdAt`, `note?` (house
  value semantics; direction is meaningful — `a supports b` is not
  `b supports a`).
- **FR-005** — Memory graph: `link(fromId, toId, type)` rejects
  self-links, duplicate links (same from/to/type — idempotent replace
  instead), and links to unknown record ids (`ArgumentError` each —
  the graph only references memories that exist in layer 1 or 2).
  `neighborsOf(recordId)` returns links where the record is EITHER
  endpoint, each tagged with `outgoing: bool`.
  `contradictions()` returns all `contradicts` links. `linksOf(type)`
  filters by type. Unmodifiable views out.
- **FR-006** — `AgentMemorySystem.remember`: with `sessionId: null`
  writes long-term; with a session id writes session memory. Returns
  the stored record.
- **FR-007** — `AgentMemorySystem.recall(String query, {int? limit})`:
  searches BOTH stores (content substring, case-insensitive), returns
  `RecallHit` (record + `MemoryLayer.longTerm | .session`) ordered by
  salience desc then createdAt desc, capped by `limit` (default no
  cap); long-term and session hits interleave in one ranking — layer
  is attribution, not partition.
- **FR-008** — `AgentMemorySystem.link` validates BOTH endpoints
  exist in either store first (graph integrity), then delegates to
  the graph. `linked(recordId)` = `neighborsOf` + resolves each
  neighbor's record and layer (records deleted later resolve to
  `null` — hits carry the link plus the record if still alive).
- **FR-009** — `promote(sessionRecordId)`: moves a record from session
  memory to long-term (removed from session store, present in
  long-term store, same id and content; createdAt preserved).
  Promoting an unknown id or an already-long-term record throws
  `ArgumentError`. Links survive untouched (graph references ids, not
  stores).
- **FR-010** — Gates: `dart analyze --fatal-infos` clean; `dart test`
  green (baseline 915/2 at `fec7889` + new tests).

## Verification

- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — baseline + new tests pass, 0 new failures

## Out of scope

- Persistence of the new layers (follows the 010
  PersistentEpisodicMemoryStore precedent in a later spec).
- Embedding/semantic retrieval (keyword + salience ranking here;
  vector search is a provider concern, spec 011 territory).
- Memory tools for the LLM (spec 074, next in this batch).
- Any modification of EpisodicMemory / AgentMessageHistory (009/010
  own those).
- Automatic memory formation (write paths here are explicit; a distiller
  that promotes automatically is future work).
