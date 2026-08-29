# Tasks: MCP Transport Resilience (spec 082)

**Input**: spec.md + plan.md under `specs/082-mcp-transport-resilience/`

**Baseline**: master `29b7fef` — `dart test` 1073 passed / 2 skipped / 0
failed; `dart analyze` 3 pre-existing issues (all out of scope:
`mission_runner` tests, `cassette_replay_llm_client`).

- [x] 1. RED — write `test/mcp/mcp_082_resilience_test.dart` (T1–T4 + T8:
       SSE recovery emits `onReconnected` once; stdio same; cache re-lists
       after recovery at the fake-client level; end-to-end SSE client + cache
       re-list; in-proc never emits). First red is the compile failure on the
       missing `McpClient.onReconnected` member; record it, then add the
       member unimplemented-style and capture the failing assertions.
       Evidence → `tdd/cycle-log.md`.
- [x] 2. GREEN — wire `onReconnected`: broadcast controllers + emission in
       `_callWithReconnect` recovery (SSE + stdio), `const Stream.empty()`
       for in-proc, `ToolListingCache` subscribes + cancels in `dispose()`,
       test fakes updated. Target file 8/8 (T1–T8).
- [x] 3. Pins — T5 jitter clamp (delay ≤ cap with jitter 0.5), T6 storm
       terminality (delays == maxAttempts, `failed`, frozen after), T7 TTL
       boundary (age == maxAge re-lists). Pass against unmodified behavior;
       each justified by a mutant.
- [x] 4. Mutations — M1 jitter clamp removed; M2 exhaustion no longer sets
       `failed`; M3 cache reconnect-subscription removed; M4 emission
       removed; M5 TTL freshness `<=`. One at a time, cp-restored, each must
       KILL.
- [x] 5. Gates — `dart analyze` (no new issues vs baseline), full `dart
       test` green (baseline 1073/2 + new).
- [x] 6. `tdd/verification.md` — evidence classification, FR table, mutation
       results verbatim, gates, verdict.
- [x] 7. Commit (artifacts + code together) and open PR base `master`
       (closes #93).
