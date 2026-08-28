# Feature Specification: Agent memory persistence — 010-style file-backed store

**Branch**: `feat/spec-076-memory-persistence` (off `feat/spec-073-agent-memory` `4dd76e2`) | **Date**: 2026-08-29

## Summary

Spec 073 delivered the three-layer agent memory (`LongTermMemoryStore`,
`SessionMemoryStore`, `MemoryGraph` behind the `AgentMemorySystem` facade) —
entirely in memory. Every process restart wiped it. This spec makes the
**durable** layers durable, following the persistence precedent set by spec
010's `PersistentEpisodicMemoryStore`:

- **Store-subclass pattern** (010): `PersistentLongTermMemoryStore extends
  LongTermMemoryStore` and `PersistentMemoryGraph extends MemoryGraph` mirror
  every mutation into a backing store and rebuild via an explicit `restore()`.
  The base classes and the facade stay untouched — persistence is a wrapper,
  not a rewrite.
- **File-backed** (this spec's twist on 010): the backing store is a JSON file
  on local disk, one per store, written **atomically** (write `*.tmp`, then
  rename over the target) so a crash mid-write can never tear the snapshot.
- **010 restore semantics**: a malformed *individual* entry is skipped, not
  fatal — one corrupt record must not lose the remaining memories. A corrupt
  *whole file* (unparseable JSON) fails loud with `StateError`: external
  damage is not silently swallowed.
- **Write-through snapshot**: every `remember` / `link` rewrites the full
  snapshot. Curated memory volumes are small (this is not the episodic log);
  a snapshot makes same-id replacement and idempotent re-link trivially
  correct.

What is deliberately **not** persisted: `SessionMemoryStore`. Session memory
is the evaporating layer by design (spec 073) — durability is earned by
promotion (manual `promote`, or the distiller spec that follows this one).
Persisting it would quietly change the layer contract.

The facade composes for free: `AgentMemorySystem(longTerm: persistent,
graph: persistentGraph)` — and because `promote()` writes through
`longTermMemory.remember(...)`, **promotions persist automatically**. That
round-trip (remember → link → promote → restart → recall) is this spec's
acceptance story.

## Files

- `lib/src/engine/persistent_agent_memory.dart` — NEW: `MemoryJsonCodec`,
  `PersistentLongTermMemoryStore`, `PersistentMemoryGraph`.
- `test/engine/persistent_agent_memory_test.dart` — NEW: unit + restart
  round-trip tests.
- `lib/src/engine/agent_memory.dart` — UNTOUCHED (persistence composes, does
  not modify; serialization lives in the codec, value objects stay pure).

## User scenarios

### US1 — Restart without amnesia (P1)

As an agent operator, I restart the process and the agent's long-term
knowledge and cross-references are still there.

**Independent test**: remember + link → new store instances on the same files
→ `restore()` → recall finds the record, the link resolves.

### US2 — Crash-safe writes (P1)

As an agent operator, a crash between writes never leaves a torn or partial
memory file.

**Independent test**: after any sequence of mutations there is no `.tmp`
leftover and the target file parses as valid JSON at every step.

### US3 — One bad entry does not lose the rest (P2)

As an agent operator, a single corrupt record in the file (e.g. manual edit
gone wrong) is skipped on restore; the healthy memories still load.

**Independent test**: hand-written file with one corrupt entry among good
ones → `restore()` → good entries present, no throw.

## Requirements

### Functional requirements

- **FR-001**: `MemoryJsonCodec` MUST losslessly round-trip `MemoryRecord`
  (id, content, tags, source, createdAt as UTC ISO-8601, salience) and
  `MemoryLink` (from, to, type by name, createdAt, note).
- **FR-002**: `PersistentLongTermMemoryStore` MUST mirror every `remember`
  into its file (write-through, full snapshot, format
  `{"version":1,"records":[...]}`).
- **FR-003**: `restore()` MUST rebuild the store from the file; a missing
  file restores to empty (first boot) without throwing.
- **FR-004**: During restore, malformed individual entries MUST be skipped;
  a wholly unparseable file MUST throw `StateError`.
- **FR-005**: Same-id replace MUST write through without duplicating the
  record in the file.
- **FR-006**: `PersistentMemoryGraph` MUST mirror every `link` (including
  idempotent re-link replacement) into `{"version":1,"links":[...]}` and
  restore losslessly.
- **FR-007**: Writes MUST be atomic — content lands in a `*.tmp` sibling
  first, then renames over the target; no `.tmp` survives a completed write.
- **FR-008**: The facade MUST compose with persistent stores such that
  `remember` (long-term), `link`, and `promote` all persist; a full
  system rebuilt from restored stores preserves recall and graph traversal.
- **FR-009**: `SessionMemoryStore` MUST NOT be persisted (evaporating layer;
  durability flows through promotion only) — documented decision.
- **FR-010**: Gates — `dart analyze --fatal-infos` exit 0; full `dart test`
  green.

### Key entities

- `MemoryJsonCodec` — encode/decode record + link JSON (static, stateless).
- `PersistentLongTermMemoryStore` — `file`, `remember()` write-through,
  `restore()`.
- `PersistentMemoryGraph` — `file`, `link()` write-through, `restore()`.

## Success criteria

- **SC-001**: Restart round-trip — records and links survive with full
  fidelity (value-object `==`).
- **SC-002**: Atomic-write invariant holds across arbitrary mutation
  sequences.
- **SC-003**: The 073 acceptance story (remember → link → promote → recall)
  now survives a restart.

## Dependencies

- Builds on: spec 073 (`feat/spec-073-agent-memory`, PR #84) — hard
  prerequisite; this branch stacks on it.
- Pattern precedent: spec 010 `PersistentEpisodicMemoryStore` (restore
  semantics, store-subclass shape).
- Feeds: spec 077 (distiller) — distilled promotions become durable by
  composing with these stores.
