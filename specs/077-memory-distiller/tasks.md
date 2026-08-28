# Tasks: Memory distiller (spec 077)

- [x] 1. RED — write `test/engine/memory_distiller_test.dart` (~11 tests:
       salience gate + boundary, identity preservation, duplicate guard
       incl. same-run siblings, cap + ranking stability, idempotency,
       unknown session, report accounting, default policy 0.7,
       persistence integration) against the missing library — must fail.
- [x] 2. GREEN — implement `lib/src/engine/memory_distiller.dart`
       (`DistillationPolicy`, `SkipReason`, `SkippedRecord`,
       `DistillationReport`, `MemoryDistiller`); full suite green.
- [x] 3. Mutations — M1 gate inverted; M2 dedup dropped; M3 cap not
       enforced; M4 ranking inverted; M5 report fabricated without
       promoting. One at a time, cp-restored, each must KILL.
- [x] 4. Gates — `dart analyze --fatal-infos` exit 0; `dart test` green
       (baseline 935/2 + new).
- [x] 5. `tdd/verification.md` — cycle integrity, FR table, mutation
       evidence verbatim, gates, findings, verdict.
- [x] 6. Commit (artifacts + code together) and open PR with base
       `feat/spec-076-memory-persistence`.
