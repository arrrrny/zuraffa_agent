# Implementation Plan: Agent memory persistence (spec 076)

## Approach

010-style store subclasses over JSON files, composable into the 073 facade.
No changes to `agent_memory.dart` — the codec lives beside the persistence
classes so the domain module stays pure and the 073 diff stays reviewable.

## Components

### 1. `MemoryJsonCodec` (static, stateless)

- `recordToJson(MemoryRecord)` / `recordFromJson(Map)` — id, content,
  tags (sorted list), source `{sessionId?, missionId?, agentName?}`,
  createdAt ISO-8601 UTC, salience.
- `linkToJson(MemoryLink)` / `linkFromJson(Map)` — fromRecordId,
  toRecordId, type (enum name), createdAt ISO, note?.
- Validation on decode mirrors constructor validation (bad salience /
  empty content / blank source → the constructor throws → the restore
  loop catches and skips, FR-004).

### 2. `PersistentLongTermMemoryStore extends LongTermMemoryStore`

- `PersistentLongTermMemoryStore({required this.file})`.
- `remember()` → `super.remember(record)` first (in-memory semantics
  unchanged), then `_writeThrough()` (snapshot all records).
- `restore()` → missing file: return; parse file (corrupt → `StateError`);
  for each entry `try recordFromJson → super.remember` — `FormatException` /
  `TypeError` / `ArgumentError` skip that entry (010 precedent).
- Snapshot format `{"version":1,"records":[...]}`, insertion order.

### 3. `PersistentMemoryGraph extends MemoryGraph`

- Same shape: `link()` → `super.link(...)` then write-through
  `{"version":1,"links":[...]}`; `restore()` same semantics.
- Idempotent re-link lands as replacement in the snapshot for free
  (full-snapshot rewrite).

### 4. Atomic write (shared helper `_atomicWrite`)

- `file.parent.createSync(recursive: true)` (operator may point at a
  not-yet-created directory).
- Write `${file.path}.tmp`, then `tmp.renameSync(file.path)`.
- Rename over an existing target is an atomic POSIX/NTFS operation —
  a reader never observes a partial snapshot.

### 5. Facade composition (FR-008) — no new code

`AgentMemorySystem(longTerm: p, graph: g)` already accepts injected stores;
`promote()` routes through `longTermMemory.remember(...)` so the override
fires. Proven by the acceptance test, not by new plumbing.

## Sequencing

1. RED: `test/engine/persistent_agent_memory_test.dart` (10 tests) against a
   missing library.
2. GREEN: `lib/src/engine/persistent_agent_memory.dart`.
3. Mutations M1–M5 (one at a time, cp-restored).
4. Gates + `tdd/verification.md` + commit + PR (base
   `feat/spec-073-agent-memory`).

## Risks / decisions

- **Full-snapshot vs append-log**: 010 appended entries into the session
  tree because episodic memory is an ordered log. Curated memory is small
  and mutable in place (same-id replace, link replace) — a snapshot is
  simpler and cannot drift. Documented tradeoff.
- **Sync file I/O**: the 073 stores are synchronous; overriding `remember`
  must keep the signature. `writeAsStringSync` on a local file at curated
  volumes is the honest fit.
- **Session store excluded**: FR-009 — evaporating by contract.
