# Test List: 108-mcp-resilience

## Outer loop: acceptance behaviors

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | Through a client with a breaker configured: N consecutive failures open the breaker, the next call fails fast typed without touching the wire, the cooldown probe recovers (success closes, failure re-opens) — composed against the fake wire (`test/mcp/mcp_120_resilience_test.dart`). | SC-002 | DONE |
| A2 | Repo gates: `dart analyze` zero findings; `dart test` green; purity gate unchanged; the `McpClient` contract names timeout, breaker, and retry (mechanical grep). | SC-004, SC-005 | DONE |

## Inner loop: unit behaviors

### Component: `lib/src/mcp/mcp_call_guard.dart`

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | N consecutive call errors open the guard (threshold from config). | FR-003 | DONE |
| U2 | A success in closed state resets the consecutive-failure count. | FR-003 | DONE |
| U3 | An open guard fails fast: the typed `circuit-open` call error is returned and the action is NEVER invoked; the fail-fast error does not feed the breaker. | FR-003 | DONE |
| U4 | After the cooldown the next call probes: success closes; failure re-opens. | FR-003 | DONE |
| U5 | A thrown transport exception counts as a failure AND propagates to the caller (reconnect contract). | FR-003 | DONE |

### Component: clients (`callTool` timeout + retry + wiring)

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U6 | A call against a never-responding wire returns the typed `timeout` error after the configured (short) duration. | FR-001 | DONE |
| U7 | Without an override the default timeout is 30s (options default observable through the contract/options object). | FR-001 | DONE |
| U8 | A read-only call whose first attempt fails transiently and second succeeds is invoked exactly twice (retry works, bounded). | FR-004 | DONE |
| U9 | A non-read-only call in the same situation is invoked exactly once. | FR-004 | DONE |
| U10 | A `timeout` result is never retried, whatever the read-only mark. | FR-002 | DONE |
| U11 | An application-level error (tool reports failure) is never retried. | FR-004 | DONE |
| U12 | The descriptor's `readOnly` flag defaults to false and round-trips (existing descriptors unaffected). | FR-006 | DONE |

## Out of scope (do not add tests)

- Half-open probe concurrency; per-tool breakers; metrics export;
  reconnect-policy changes (spec 082 surface).

## Verification commands

```bash
dart test test/mcp/
dart test
dart analyze
rg -n "dart:io" lib/src/mcp/mcp_call_guard.dart   # expect: no matches
```
