# TDD Cycle Log: Session storage schema versioning (spec 110)

## Baseline

- **planned_at**: 2026-09-09, branch `110-session-schema-versioning` (off post-#145 master)
- **suite**: 1268 passed, 0 failed, ~2 skipped; analyzer clean
- **misfire protocol**: user-authorized report-and-continue (same as 105–109).

## Cycle 1 — the migrator registry (U1–U3)

### RED

```
$ dart test test/session_storage/migration_test.dart
  15 compile errors (session_migrator.dart absent, StoreOpenResult fields absent)
```

### GREEN

`SessionMigrator` (ordered registry keyed by from-version, shipped 1→2 / 2→3
stamp steps) + `SessionSchema` + `StoreOpenResult.schemaVersion` /
`migratedFromVersion`. In-cycle mechanics fixes: tests use
`SessionMigrator.standard().migrate` (instance registry), the JSONL
constructor is positional, and the v1 fixture was reshaped to the real
`MessageEntry` map (nested `message`, no flat role/content).

```
$ dart test test/session_storage/migration_test.dart → 3 passed (migrator group)
```

## Cycle 2 — JSONL header + legacy migration (U4–U8, A1)

### RED

JSONL group: 5 failing (no header/migration in init).

### GREEN

`init()` gains version detection (first non-empty line carries `_schema`;
absence = v1), future-version rejection, per-entry raw-map migration before
deserialization, and an atomic rewrite (temp + rename) with the
current-version header. In-cycle fixture fix: the v1 fixture's second line
was still the flat legacy shape (caught by the test — count 1 of 2).

```
$ dart test test/session_storage/migration_test.dart → 8 passed
```

## Cycle 3 — Hive version stamp (U9)

### RED

```
$ dart test test/session_storage/hive_version_test.dart
  Expected: <3>
    Actual: <null>
```

### GREEN

Hive meta box gains `schemaVersion`: absent = legacy → stamped forward at
open; the result reports the (stamped) version and migration source.

```
$ dart test test/session_storage/hive_version_test.dart → 1 passed
```

## Audit mutant (post-cycle)

```
MUTANT: legacy migration disabled (needsMigration forced false)
A1: a v1 fixture migrates to v3 in memory and on disk [E]
  Expected: <1>
    Actual: <null>
```

Killed by A1 (migratedFromVersion assertion). Restored exactly; suite
green; analyze clean.
