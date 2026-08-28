# Cycle Log: Tools & MCP Client (spec 003)

Append only. Newest last. This file currently holds only the Baseline entry; no
cycles have been driven yet because `plan.md` is absent and the outer-only TDD
plan is being recorded before any change.

## Baseline

- suite: `dart test` -> 909 passed, 2 skipped (0 failed)
- commit: `fce207d`
- recorded: cycle 0, before any change

## Cycle: A6 — mid-mission SSE drop reconnects and resumes listing + calls

- test: `test/mcp/mcp_003_a6_reconnect_test.dart` :: "A6: a mid-mission SSE drop
  reconnects with backoff and resumes both tool listing and tool calls"
- RED: first run failed to compile —
  `Error: The getter 'payload' isn't defined for the type 'McpCallOk'.` That is a
  broken-test red, not a behavior red, so per the playbook it does not count as
  evidence; the field is `result`. After the fix the test PASSED on its first
  real run, so the deliberate-mutant check applies.
- Deliberate mutant: removed `_reconnect.reset()` from the successful-send path
  in `lib/src/mcp/sse_mcp_client.dart` -> A6 failed with
  `Expected: [0:00:00.100000, 0:00:00.100000] Actual: [0:00:00.100000,
  0:00:00.200000]` — the second drop's backoff escalated instead of restarting.
  Restored; A6 green again.
- GREEN: no production change needed. Spec 015's `SseMcpClient` +
  `McpReconnectPolicy` already satisfy the acceptance claim; A6 is the
  acceptance-level test that was missing — two drops on one client instance, at
  two different mission points (listing, then calling), with the backoff
  sequence observed through the injected delay.
- No refactor needed.
- Full suite green (946 passed, 2 skipped, 62s).
- commit: (this cycle)
