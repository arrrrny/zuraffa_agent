# Implementation Plan: Session storage schema versioning (issue #122)

**Branch**: `110-session-schema-versioning` | **Date**: 2026-09-09 | **Spec**: [spec.md](./spec.md)

## Summary

Schema version 3 becomes the explicit current contract. JSONL gains a
header line + legacy detection + in-memory migration + atomic rewrite at
open; Hive gains a meta-box version stamp; `StoreOpenResult` reports the
open schema version and migration source; `SessionMigrator` is the ordered
step registry (1→2 stamps v2, 2→3 stamps v3); `ARCHITECTURE.md` documents
the policy.

## Key decisions (research headlines)

- No header = v1 (the whole pre-versioning corpus).
- Migrations run on RAW entry maps before `fromJson`; unknown keys survive
  deserialization, so additive stamps are safe.
- Rewrite is atomic (temp + rename), reusing the JsonlEntityStorage
  precedent; the tear-scan only runs on the legacy section as today.
- A file at a version GREATER than current fails the open (no downgrades).
- Hive: detection + stamping only (hydrated objects, not raw maps) —
  documented as the deferred-migration hook.

## Files

```text
lib/src/session_storage.dart          # EDIT: SessionSchema + StoreOpenResult fields
lib/src/session_migrator.dart         # NEW: registry + steps
lib/src/jsonl_session_storage.dart    # EDIT: header + legacy migration + rewrite
lib/src/hive_session_store.dart       # EDIT: meta-box version stamp
ARCHITECTURE.md                       # NEW: storage + migration policy
test/session_storage/migration_test.dart      # NEW
test/session_storage/hive_version_test.dart   # NEW
```

## Constitution Check

I/V/X PASS; VII PASS (JSONL file stays allowlisted; migrator is pure);
IX n/a. Baseline: 1268 passed / 0 failed, analyzer clean.

## Sequencing

tdd.plan → tdd.run (migrator units → JSONL legacy/native/fresh → Hive →
acceptances) → tdd.verify → PR (closes #122).
