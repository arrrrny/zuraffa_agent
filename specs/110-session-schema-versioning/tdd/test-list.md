# Test List: 110-session-schema-versioning

## Outer loop: acceptance behaviors

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | A v1 fixture file (no header) opens with every entry in memory at the current version, reports migratedFromVersion 1, and is rewritten with the v3 header — the issue's own acceptance test (`test/session_storage/migration_test.dart`). | SC-001 | DONE |
| A2 | Repo gates: `dart analyze` zero; `dart test` green; purity gate unchanged; `ARCHITECTURE.md` documents the migration policy (mechanical grep). | SC-005, SC-006 | DONE |

## Inner loop: unit behaviors

### Component: `lib/src/session_migrator.dart`

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | A v1 raw entry map migrates through both registered steps to the current version (stamps visible). | FR-004 | DONE |
| U2 | A map already at the current version is returned unchanged. | FR-004 | DONE |
| U3 | An entry-map version greater than current is rejected with a clear error. | FR-004 | DONE |

### Component: `lib/src/jsonl_session_storage.dart`

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U4 | Legacy file (no header): open migrates, result reports schemaVersion + migratedFromVersion, entries deserialize. | FR-001, FR-005 | DONE |
| U5 | The legacy file is rewritten with the v3 header; the header line is not surfaced as an entry. | FR-001, FR-002 | DONE |
| U6 | A current-version file opens with no migration (schemaVersion reported, no migratedFrom). | FR-002, FR-005 | DONE |
| U7 | A file at a future version fails the open with a clear error. | FR-004 | DONE |
| U8 | A fresh (non-existent) store writes the header on first init. | FR-003 | DONE |

### Component: `lib/src/hive_session_store.dart`

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U9 | A fresh Hive store stamps the meta-box version and reports it on the result. | FR-003, FR-005 | DONE |

## Out of scope (do not add tests)

- Hive value-level migrations; backup/restore; retention; tearing interplay
  beyond the existing tear-scan behavior.

## Verification commands

```bash
dart test test/session_storage/
dart test
dart analyze
rg -n "migration" ARCHITECTURE.md
```
