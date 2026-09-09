# Tasks: Session storage schema versioning (issue #122)

**Tests**: TDD-driven — every behavior on `tdd/test-list.md` (A1–A2, U1–U9)
is observed failing before its implementation.

- [x] T001 Create `specs/110-session-schema-versioning/` with spec.md seeded
  from issue #122 (done by `/speckit.specify`)
- [x] T002 Write `/speckit.plan` artifacts: plan.md, this tasks.md,
  tdd/test-list.md, cycle-log baseline

## Phase 2: The migrator (pure core)

- [ ] T003 [P] Test `test/session_storage/migration_test.dart` (migrator
  group) — [U1] v1 map → current through both steps, [U2] current map
  unchanged, [U3] future version rejected.
- [ ] T004 Implement `lib/src/session_migrator.dart` (ordered registry,
  shipped 1→2 and 2→3 steps, `migrate`) — makes [U1]–[U3] green.

## Phase 3: JSONL header + legacy migration

- [ ] T005 [P] Test `test/session_storage/migration_test.dart` (jsonl
  group) — [U4] legacy open migrates + reports, [U5] rewrite carries the
  header (not an entry), [U6] native open no-migration, [U7] future version
  rejected, [U8] fresh store writes the header.
- [ ] T006 Implement JSONL header + legacy detection + in-memory migration
  + atomic rewrite in `lib/src/jsonl_session_storage.dart`; `SessionSchema`
  + `StoreOpenResult` fields in `lib/src/session_storage.dart` — makes
  [U4]–[U8] green and closes [A1].

## Phase 4: Hive stamp + docs

- [ ] T007 [P] Test `test/session_storage/hive_version_test.dart` — [U9]
  fresh store stamps the meta version and reports it.
- [ ] T008 Implement the Hive meta-box stamp in
  `lib/src/hive_session_store.dart` — makes [U9] green.
- [ ] T009 Write `ARCHITECTURE.md` (storage + migration policy) — closes
  [A2]'s documentation gate.

## Phase 5: Gates + verify

- [ ] T010 Acceptance [A1]: the v1-fixture end-to-end test green.
- [ ] T011 Acceptance [A2] gates: analyze zero, suite green, purity
  unchanged, ARCHITECTURE.md grep.
- [ ] T012 Run `/speckit.tdd.verify` → `tdd/verification.md`; commit
  (`feat(110):`), push, open PR closing #122.
