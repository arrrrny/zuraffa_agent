# Tasks: Agent memory persistence (spec 076)

- [x] 1. RED — write `test/engine/persistent_agent_memory_test.dart` (10
       tests: write-through, round-trip, replace, malformed-skip, missing
       file, corrupt file, graph round-trip, idempotent re-link, atomic
       writes, full-system restart story) and run against the missing
       library — must fail.
- [x] 2. GREEN — implement `lib/src/engine/persistent_agent_memory.dart`
       (`MemoryJsonCodec`, `PersistentLongTermMemoryStore`,
       `PersistentMemoryGraph`, atomic `_atomicWrite`); full suite green.
- [x] 3. Mutations — M1 write-through dropped; M2 restore no-op; M3 no
       malformed-skip; M4 rename skipped (tmp only); M5 codec drops tags.
       One at a time, cp-restored, each must KILL.
- [x] 4. Gates — `dart analyze --fatal-infos` exit 0; `dart test` green;
       record real counts vs baseline 935/2 (074 branch tip
       `9855875`… base here is 073 tip `4dd76e2`, baseline 925/2).
- [x] 5. `tdd/verification.md` — cycle integrity, FR table, mutation
       evidence verbatim, gates, findings, verdict.
- [x] 6. Commit (artifacts + code together) and open PR with base
       `feat/spec-073-agent-memory`.
