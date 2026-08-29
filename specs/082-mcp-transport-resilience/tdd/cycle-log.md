# TDD Cycle Log: MCP Transport Resilience (spec 082)

Append-only record of the red-green-refactor cycles. One entry per cycle;
RED evidence quoted verbatim from the failing runs.

## Cycle 1 — `McpClient.onReconnected` + cache wiring (behaviors U1–U4)

**Scope**: interface member, SSE/stdio emission, in-proc silence,
`ToolListingCache` invalidation on recovery. Tests T1–T4 + T8 written
FIRST, in full, before any production edit.

### RED

Step 1 — the test file alone (production untouched):

```
$ dart test test/mcp/mcp_082_resilience_test.dart
test/mcp/mcp_082_resilience_test.dart:125:14: Error: The getter
  'onReconnected' isn't defined for the type 'SseMcpClient'.
test/mcp/mcp_082_resilience_test.dart:158:14: Error: The getter
  'onReconnected' isn't defined for the type 'StdioMcpClient'.
test/mcp/mcp_082_resilience_test.dart:248:14: Error: The getter
  'onReconnected' isn't defined for the type 'InProcMcpClient'.
```

Step 2 — interface member added with a never-emitting default (and trivial
overrides so `implements` compiles), NO emission, NO cache subscription:

```
$ dart test test/mcp/mcp_082_resilience_test.dart
00:00 +4 -4: Some tests failed.

Failing tests:
  ... T3: onReconnected invalidates a TTL-fresh cache entry
  ... T4: end-to-end — drop + recovery → the cache re-lists (SC-002)
  ... T1: SSE drop mid-call → recovery → onReconnected fires exactly once
  ... T2: stdio drop mid-call → recovery → onReconnected fires once
```

4 failing (the new behavior), 4 passing (T5–T8: pins + in-proc silence —
pass against current behavior by design).

### GREEN

Smallest change set: broadcast `_reconnectedController` + post-transition
`add(null)` in `_callWithReconnect` (SSE + stdio), controller closed in
`disconnect()`, cache subscribes `client.onReconnected → invalidate()` and
cancels in `dispose()`. The two pre-existing `McpClient` test fakes grow
the member (compile fix).

```
$ dart test test/mcp/mcp_082_resilience_test.dart
00:00 +8: All tests passed!
```

### REFACTOR

Reviewed the diff; no duplication worth extracting (the emission comment is
duplicated across SSE/stdio deliberately — the files are parallel by house
style). No behavior change.

## Cycle 2 — pins over existing behavior (U5–U7)

**Scope**: T5 (jitter clamp), T6 (storm terminality), T7 (TTL boundary).
These pin behavior that ships on master unguarded — they pass by design
and are justified by killer mutants M1/M2/M5 (below), per the 078
"pin honesty" precedent. No production change in this cycle.

### RED (honesty note)

Pins are NOT red: they pass against current master behavior. The red
evidence for the behaviors they guard is the mutation kills.

### GREEN

```
$ dart test test/mcp/mcp_082_resilience_test.dart
00:00 +8: All tests passed!
$ dart test test/mcp/
00:00 +58: All tests passed!
```

## Mutations (deliberate, one at a time, cp-restored)

| id  | mutant | result | evidence |
| --- | ------ | ------ | -------- |
| M1  | jitter clamp removed in `McpReconnectPolicy.nextBackoff` | KILLED by T5 | `Expected: a value less than or equal to <1000>` / `Actual: <1350>` / `1350ms exceeds the cap — jitter must be clamped` |
| M2  | exhaustion no longer transitions SSE client to `failed` | KILLED by T6 | `Expected: McpClientState:<McpClientState.failed>` / `Actual: McpClientState:<McpClientState.connected>` |
| M3  | cache's `onReconnected` subscription removed | KILLED by T3 + T4 | 2 tests failed (`Some tests failed.` +6 -2) |
| M4  | SSE recovery emission removed | KILLED by T1 + T4 | 2 tests failed (`Some tests failed.` +6 -2) |
| M5  | TTL freshness `<=` instead of `<` | KILLED by T7 | `Expected: <2>` / `Actual: <1>` / `freshness is age < maxAge — age == maxAge is stale` |

After each restore the target file returned to 8/8 green.

## Gates

```
$ dart analyze            # 3 issues — identical to master baseline (out of scope)
$ dart test               # 00:40 +1081 ~2: All tests passed!
```

Baseline at master `29b7fef` was 1073 passed / 2 skipped; +8 new tests.
