**Template Version**: `zuraffa-1.0`

# Feature Specification: Session storage schema versioning + migration path

**Branch**: `110-session-schema-versioning` | **Date**: 2026-09-09

**Status**: Draft

**Input**: GitHub issue #122 — "Add schema versioning + migration path to
session storage". Severity: high (persistence).

## Summary

`SessionStorage` has no schema version: JSONL files carry no header, Hive
boxes carry no meta key, and old persisted sessions break silently when the
`SessionTreeEntry` schema evolves. This spec makes the persisted schema an
explicit, versioned, migratable contract:

1. **Current schema version = 3**, declared as a constant.
2. **JSONL**: a header line (`{"_schema":{"schemaVersion":N}}`) is the
   first line of every new/migrated file; files without one are **legacy
   v1** and are migrated in-memory and rewritten (header + entries) at
   open.
3. **Hive**: the meta box carries the `schemaVersion` key; `init` stamps it.
4. **`SessionMigrator`** — a registry of per-version steps
   (`1→2`, `2→3`) operating on raw entry maps before deserialization;
   extensible by adding a step.
5. **`init()` reports** `schemaVersion` (and, when a migration ran, the
   version migrated from) on `StoreOpenResult`.
6. **Migration policy documented** in a new `ARCHITECTURE.md`.

Shipped migration steps (v1→v2, v2→v3) stamp each entry map with its
`schemaVersion` — the real historical divergences don't exist yet; the
machinery, registry, and rewrite path are the deliverable, so the next real
schema change is a one-function addition.

**Out of scope**: Hive value-level migrations (Hive stores hydrated
objects, not raw maps — version stamping + detection only, documented);
backup/restore (#135); retention/TTL; changing `SessionTreeEntry`'s schema.

## Files

- `lib/src/session_storage.dart` — EDIT: `SessionSchema` (current version
  constant), `StoreOpenResult` gains `schemaVersion` / `migratedFromVersion`
  (additive, defaulting null).
- `lib/src/config/…` no — `lib/src/session_migrator.dart` — NEW: the
  registry + the two shipped steps + `migrate(rawMap, fromVersion)`.
- `lib/src/jsonl_session_storage.dart` — EDIT: header write/parse, legacy
  detection, in-memory migration, atomic rewrite.
- `lib/src/hive_session_store.dart` — EDIT: meta-box version stamp/read.
- `ARCHITECTURE.md` — NEW: storage + migration policy section.
- `test/session_storage/migration_test.dart`, `test/session_storage/hive_version_test.dart` — NEW.
- `specs/110-session-schema-versioning/` — this artifact set.

## User scenarios

### US1 — Old files keep working, and say so (P1)

As an operator upgrading the engine, opening a legacy session file
migrates it transparently: every entry loads, the store reports which
version it migrated from, and the file on disk is upgraded (header +
stamped entries) so the next open is a native open.

**Acceptance**: a v1 fixture file (no header, entry maps without version
stamps) opens with every entry readable in memory, reports
`schemaVersion: 3` / `migratedFromVersion: 1`, and the file on disk now
carries the v3 header.
**Acceptance Scenarios**:

1. **Given** a v1 fixture file (no header, entry maps without version stamps), **When** it opens, **Then** every entry is readable in memory, the open reports `schemaVersion: 3` / `migratedFromVersion: 1`, and the file on disk now carries the v3 header.
### US2 — Native files open without churn (P1)

As the engine, a current-version file opens with no migration work: the
result reports the current version and no migration source; the header is
preserved.

**Acceptance**: opening a v3 file reports `schemaVersion: 3` and no
`migratedFromVersion`; entries load unchanged.

**Acceptance Scenarios**:

2. **Given** a v3 file, **When** it opens, **Then** the result reports `schemaVersion: 3` with no `migratedFromVersion` and the entries load unchanged.

**Acceptance**: `init()` on a non-existent JSONL path creates the file with
the v3 header; a fresh Hive store stamps its meta box with the current
version; both report it.

**Acceptance Scenarios**:

2. **Given** a v3 file, **When** it opens, **Then** the result reports `schemaVersion: 3` with no `migratedFromVersion` and the entries load unchanged.

As a maintainer, the next schema change is one function: add a step to the
registry, bump the version constant, add a fixture test. The migrator
chains steps in order (1→2→3) and no-ops when a map is already current.

**Acceptance**: `SessionMigrator.migrate` walks the registered chain from a
map's version to the current version; a v1 map comes out carrying the v3
stamp through both steps; a map already at the current version is returned
unchanged.
## Requirements

**Acceptance Scenarios**:

2. **Given** a v3 file, **When** it opens, **Then** the result reports `schemaVersion: 3` with no `migratedFromVersion` and the entries load unchanged.
### Functional requirements

- **FR-001**: legacy JSONL files (no header) are treated as v1,
  migrated through the registry to the current version, and rewritten
  atomically with a header before any tear-scan result is produced.
  traces: SessionStorage.fr1
- **FR-002**: current-version JSONL files open without migration;
  the header line is not surfaced as an entry.
  traces: SessionStorage.fr2
- **FR-003**: new JSONL stores write the header on first init; new
  Hive stores stamp the meta box.
  traces: SessionStorage.fr3
- **FR-004**: `SessionMigrator` exposes the ordered registry
  (`1→2`, `2→3`) and migrates raw entry maps from any registered version to
  the current version; current-version maps are returned unchanged.
  traces: SessionStorage.fr4
- **FR-005**: `StoreOpenResult` carries `schemaVersion` and, when a
  migration ran, `migratedFromVersion`.
  traces: SessionStorage.fr5
- **FR-006**: the migration policy (version constant, header shape,
  legacy-defaults-to-v1, registry extension steps) is documented in
  `ARCHITECTURE.md`.
  traces: SessionStorage.fr6

## Success criteria

- **SC-001** (US1 / FR-001): a v1 fixture opens to every entry in memory at
  the current version, with `migratedFromVersion: 1` reported and the file
  rewritten with the v3 header — the issue's own acceptance test.
- **SC-002** (US2 / FR-002): a v3 file opens with no migration.
- **SC-003** (US3 / FR-003): fresh stores are born at the current version
  (JSONL header; Hive meta key).
- **SC-004** (US4 / FR-004): the migrator chain is proven (v1 → v3 through
  both steps; no-op at current).
- **SC-005**: `ARCHITECTURE.md` documents the policy (mechanical check).
- **SC-006**: `dart analyze` pristine; suite green; purity gate unchanged
  (Hive's dart:io stays quarantined in its existing allowlisted file).

## Assumptions

- Absence of a header means v1 — the entire pre-versioning corpus is v1 by
  definition.
- Migration steps operate on raw entry maps BEFORE `fromJson`; unknown keys
  survive (the deserializer ignores them), so stamping is additive and
  safe.
- An unknown schema version GREATER than the current one fails the open
  with a clear error (downgrade is not supported).
- Hive value-level migrations are deferred: Hive stores hydrated objects;
  its version stamp enables detection so a future real divergence has the
  hook ready.

## Dependencies

- Builds on: master (post-#145) — JSONL/Hive stores (specs 002/010/076),
  the atomic-rewrite precedent in `JsonlEntityStorage`.
- Pairs with (out of scope): backup/restore (#135), retention (#135).

## Layer Contracts

**Domain**:

- `SessionStorage`: `fr1(...) -> Result`, `fr2(...) -> Result`, `fr3(...) -> Result`, `fr4(...) -> Result`, `fr5(...) -> Result`, `fr6(...) -> Result`

