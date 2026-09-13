**Template Version**: `zuraffa-1.0`

# Feature Specification: JsonlSessionStorage single-writer lock + streaming entries()

**Branch**: `114-jsonl-single-writer-streaming` | **Date**: 2026-09-11

**Status**: Draft

**Input**: GitHub issue #136 — "Fix `JsonlSessionStorage` concurrent-write
race + add streaming `entries()`". Severity: medium (area:persistence,
area:performance).

## Summary

`JsonlSessionStorage.appendEntry` opens the file in append mode with no
locking: two in-process writers sharing a JSONL path can interleave or
lose updates, and the in-memory entry map is unsynchronized. Separately,
`getEntries()` fully materializes the store — a 100k-entry session
OOMs the process. This spec adds (1) an in-process mutex around every
`JsonlSessionStorage` mutation via `package:synchronized`, (2) an
advisory cross-writer `SessionLock` (a lock sidecar file held for the
store's lifetime, so two MissionRunners on one path fail fast instead of
corrupting), and (3) a lazy `Stream<SessionTreeEntry> entries()` on the
`SessionStorage` interface alongside the eager `getEntries()`.

**Out of scope**: Hive cross-process locking (documented
single-writer-only), a memory/load regression harness (issue #128's load
tests), and network file systems' lock semantics.

## Files

- `pubspec.yaml` — MODIFIED: add `synchronized`.
- `lib/src/session_storage.dart` — MODIFIED: `Stream<SessionTreeEntry>
  entries()` on the interface.
- `lib/src/session_storage_impl.dart` — MODIFIED: in-memory `entries()`.
- `lib/src/hive_session_store.dart` — MODIFIED: lazy `entries()` over box
  keys; single-writer documentation.
- `lib/src/jsonl_session_storage.dart` — MODIFIED: mutation mutex +
  lazy `entries()` + `SessionLock` integration.
- `lib/src/session_lock.dart` — NEW: advisory sidecar-file lock
  (`<path>.lock`) with acquire/release and stale-lock notes.
- `test/tdd/114-jsonl-single-writer-streaming/` — gen'd behavior tests.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Concurrent writers cannot corrupt the log (Priority: P1)

Two `JsonlSessionStorage` instances in one process append to the same
path concurrently; every entry from both survives, each on its own line.

**Why this priority**: this is the corruption defect the issue reports.

**Independent Test**: interleave `appendEntry` calls from two stores on
one path under the mutex; reopen and assert both entries parse.

**Acceptance Scenarios**:

1. **Given** two stores appending to one JSONL path interleaved,
   **Type**: acceptance
   **When** both finish and the file is reopened, **Then** every entry
   from both writers is present and deserializable (no interleaved or
   torn lines).
2. **Given** a store with a held `SessionLock` sidecar, **When** a second
   **Type**: acceptance
   store is opened on the same path, **Then** acquisition fails fast
   with a `StateError` naming the path (single-writer enforced, not
   silently shared).

### User Story 2 — Entries stream lazily (Priority: P1)

A mission runner or UI can iterate entries without materializing the
whole store; `entries()` streams and supports early exit.

**Why this priority**: the OOM half of the issue — 100k-entry sessions
must not require full materialization.

**Independent Test**: seed a store, take `entries()` with early exit
(`take(2)`), and assert no more than the taken entries were pulled.

**Acceptance Scenarios**:

3. **Given** a JSONL store with several entries, **When** `entries()` is
   **Type**: acceptance
   iterated with early exit, **Then** iteration stops without requiring
   the remaining entries and the yielded entries match the seeded ones.
4. **Given** Hive and in-memory stores with entries, **When** `entries()`
   **Type**: acceptance
   is iterated, **Then** the same entry set is yielded as
   `getEntries()`.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Every `JsonlSessionStorage` mutation (`appendEntry`,
  `deleteEntries`, `setActiveLeafId`, `close`) MUST run under a
  process-wide mutex so interleaved calls serialize.
  traces: JsonlSessionStorage.guard
- **FR-002**: `JsonlSessionStorage.init` MUST acquire an advisory
  `SessionLock` sidecar (`<path>.lock`) and hold it until `close`;
  a second writer on the same path MUST fail fast with a `StateError`
  naming the path.
  traces: SessionLock.acquire
- **FR-003**: `SessionStorage.entries()` MUST return a lazy
  `Stream<SessionTreeEntry>`; early exit MUST NOT force the remaining
  entries. All three implementations (in-memory, Hive, JSONL) MUST ship
  it.
  traces: SessionStorage.entries
- **FR-004**: Hive persistence MUST document its single-writer
  assumption in the class header (no cross-process lock).
  traces: SessionStorage.entries

### Non-Functional Requirements

- NFR-001: `dart:io` usage stays quarantined in the existing allowlisted
  files (spec 064 discipline).

## Layer Contracts

**Domain**:

- `SessionLock`: `acquire() -> Future<void>`, `release() -> Future<void>`
- `JsonlSessionStorage`: `guard(mutation) -> Future<void>`

### Key Entities

| Entity | Fields | Purpose |
|--------|--------|---------|
| `SessionLock` | `path: String`, `_held: bool` | Advisory single-writer sidecar lock |

### External Dependencies & Contracts

| Dependency | Kind | Contract | Priority |
|--------|--------|--------|--------|
| package:synchronized | pub dependency | `Lock` critical-section mutex | P1 |
| Hive | pub dependency | hive_ce `Box<K>` lazy key iteration (`keys`, `getAt`) | P1 |
| dart:io | SDK (quarantined) | `File.lock` advisory sidecar locking | P1 |

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: US1 fixtures pass — interleaved appends all survive;
  second open on a locked path fails fast (FR-001, FR-002).
- **SC-002**: US2 fixtures pass — lazy streaming with early exit across
  all three stores (FR-003).
- **SC-003**: Hive header documents single-writer (FR-004).
- **SC-004**: `dart analyze` zero; full suite green; purity gate
  unchanged.
