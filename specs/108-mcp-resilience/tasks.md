# Tasks: MCP resilience (issue #120)

**Tests**: TDD-driven — every behavior on `tdd/test-list.md` (A1–A2, U1–U12)
is observed failing before its implementation.

- [x] T001 Create `specs/108-mcp-resilience/` with spec.md seeded from
  issue #120 (done by `/speckit.specify`)
- [x] T002 Write `/speckit.plan` artifacts: plan.md, this tasks.md,
  tdd/test-list.md, cycle-log baseline

## Phase 2: The guard (pure core)

- [x] T003 [P] Test `test/mcp/mcp_call_guard_test.dart` — [U1] threshold
  opens, [U2] success resets, [U3] open fails fast typed without invoking
  and does not self-feed, [U4] cooldown probe recovers both ways, [U5]
  thrown exceptions count + propagate.
- [x] T004 Implement `lib/src/mcp/mcp_call_guard.dart` (`McpCallGuard`,
  `McpBreakerConfig`, `McpRetryConfig`, `McpCallOptions` with the 30s
  default) — makes [U1]–[U5] green.

## Phase 3: Client wiring

- [x] T005 [P] Test `test/mcp/mcp_120_resilience_test.dart` — [U6] hung
  wire → typed timeout, [U7] default 30s observable, [U8] read-only retry
  bounded, [U9] non-read-only never retried, [U10] timeout never retried,
  [U11] app errors never retried, [U12] descriptor readOnly default +
  round-trip.
- [x] T006 Implement client wiring: options on `McpClient.callTool`
  (interface + Sse/Stdio/InProc), timeout, guard, retry; descriptor
  `readOnly` flag; contract documentation — makes [U6]–[U12] green and
  closes [A1].

## Phase 4: Acceptance gates + verify

- [x] T007 Acceptance [A1]: breaker sequence through the client.
- [x] T008 Acceptance [A2] gates: analyze, suite, purity, contract grep.
- [x] T009 Run `/speckit.tdd.verify` → `tdd/verification.md`; commit
  (`feat(108):`), push, open PR closing #120.
