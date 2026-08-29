# Tasks: Usage Ledger — token accounting projection (spec 083)

**Input**: spec.md + plan.md under `specs/083-usage-ledger/`

**Baseline**: master `29b7fef` — `dart test` 1073 passed / 2 skipped / 0
failed; `dart analyze` 3 pre-existing issues (all out of scope).

- [x] 1. RED — write `test/usage_ledger_083_test.dart` (T1–T7: equality +
       hash consistency; inequality; round-trip serialization with cache
       tokens and a null-model entry; empty-ledger edge; immutability
       (source-list mutation + `entries` mutation); sub-ledger round-trip
       equality; chained byModel∘byTurn pin). First red is the compile
       failure on the missing `toJson`/`fromJson`/`entries` members, then
       failing equality/round-trip assertions with members present but `==`
       absent. Evidence → `tdd/cycle-log.md`.
- [x] 2. GREEN — defensive copy (`List.unmodifiable`), `entries` getter,
       `toJson`/`fromJson`, `==`/`hashCode` through the lazy memoized
       encoded form. Target file 7/7.
- [x] 3. Pin — T7 chaining verified against unmodified behavior; the
       pre-existing `test/usage_ledger_test.dart` stays green unmodified
       (FR-005 regression guard).
- [x] 4. Mutations — M1 length-only equality; M2 fromJson zeroes cache
       tokens; M3 defensive copy removed; M4 toJson drops the model. One at
       a time, cp-restored, each must KILL.
- [x] 5. Gates — `dart analyze` (no new issues vs baseline), full `dart
       test` green (baseline 1073/2 + new).
- [x] 6. `tdd/verification.md` — evidence classification, FR table,
       mutation results verbatim, gates, verdict.
- [x] 7. Commit (artifacts + code together) and open PR base `master`
       (closes #94).
