# Test List: MCP Transport Resilience (spec 082)

---
feature: 082-mcp-transport-resilience
loop: outside-in
profile: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md
spec_criteria: 8 # FR-001..FR-008 in spec.md
planned_at: master (29b7fef)
updated_at: 082-mcp-transport-resilience
suite_baseline: green # 1073 passed / 2 skipped at 29b7fef
---

## Outer loop: acceptance behaviors

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| A1  | A transient wire drop is survivable AND observable end-to-end: mid-call drop → capped-backoff recovery → the call returns its real result, `onReconnected` fires once, and a TTL-fresh `ToolListingCache` re-lists on next demand | FR-004, FR-005, SC-001, SC-002 | example | PLANNED | `test/mcp/mcp_082_resilience_test.dart` (T4 end-to-end; T1/T3 parts) |
| A2  | Gates: `dart analyze` clean vs baseline (3 pre-existing, out of scope); full `dart test` green (baseline 1073/2 + new) | FR-008 | gate | PLANNED | gates at branch HEAD (counts in verification.md) |

## Inner loop: unit behaviors

### New surface (RED): `McpClient.onReconnected` + cache wiring

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U1  | SSE: drop mid-call → recovery → the call returns its real result AND `onReconnected` fired exactly once (not on initial connect) | FR-004 | unit | PLANNED | T1 |
| U2  | stdio: same recovery emission contract | FR-004 | unit | PLANNED | T2 |
| U3  | Cache: primed + served within TTL → `onReconnected` fires → next `getOrRefresh()` re-lists (`listToolsCallCount` 1 → 2) | FR-005 | unit | PLANNED | T3 |
| U4  | `InProcMcpClient.onReconnected` never emits | FR-004 | unit | PLANNED | T8 |

### Pins (pass against current master behavior by design)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U5  | Jitter never pushes an applied backoff delay past `config.cap` (the clamp) | FR-002 | pin | PLANNED | T5 (mutant M1) |
| U6  | Storm terminality: always-dropping wire → exactly `maxAttempts` delays, client `failed`, and a post-failure `callTool` schedules no further delays | FR-003 | pin | PLANNED | T6 (mutant M2) |
| U7  | TTL boundary: an entry aged exactly `maxAge` is stale — next `getOrRefresh()` re-lists | FR-006 | pin | PLANNED | T7 (mutant M5) |

> **Pin honesty**: U5–U7 pin behavior that ships on master unguarded; they
> pass by design and are justified by killer mutants M1/M2/M5. FR-001 and
> FR-007 are covered by the existing 015/003 tests cited below — no
> duplicates written.

## Edge cases & invariants

- Initial `connect()` must NOT fire `onReconnected` (only recoveries do).
- `dispose()` cancels the reconnect subscription (no leak, no post-dispose
  invalidation crash).
- Post-failure `callTool` returns `McpCallError('client-not-connected')`
  without touching the wire or the delay recorder.
- Emission happens after the state transition — a listener inspecting
  `client.state` on the event sees `connected`.

## Out of scope

- Backoff formula / config changes (015 owns them).
- Auth-token rotation (015 FR-003, already tested).
- `io_sse_mcp_transport.dart` / `io_stdio_mcp_transport.dart` (purity
  allowlist, unchanged).
- FR-001 / FR-007 duplicates of existing tests: `test/mcp/_fake_wire.dart`
  consumers, `test/mcp/mcp_tool_adapter_test.dart` (namespace),
  `test/mcp/sse_mcp_client_test.dart` (sealed result mapping),
  `test/mcp/mcp_003_a6_reconnect_test.dart` (drop-resume acceptance).

## Verification commands

```bash
dart analyze
dart test test/mcp/mcp_082_resilience_test.dart
dart test
```
