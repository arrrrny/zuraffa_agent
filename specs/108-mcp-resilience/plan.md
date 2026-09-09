# Implementation Plan: MCP resilience (issue #120)

**Branch**: `108-mcp-resilience` | **Date**: 2026-09-09 | **Spec**: [spec.md](./spec.md)

## Summary

A pure `McpCallGuard` (mutable holder over the immutable `CircuitBreaker`,
injectable clock) provides fail-fast + probe recovery; `McpCallOptions`
(timeout, retry, readOnly mark) ride the existing `callTool` seam as an
additive optional parameter; the SSE/stdio clients wire guard + timeout +
retry; InProc passes options through unchanged in behavior. The descriptor
gains an additive `readOnly` flag. The `McpClient` contract documents all
three behaviors. Nothing above `McpClient` changes.

## Key decisions (research headlines)

- **Guard**: the immutable breaker (spec 035) is wrapped, not reimplemented —
  the guard owns "which snapshot is current" and drives
  `shouldProbe`/`tryHalfOpen` with an injected clock. Open → typed
  `circuit-open` call error WITHOUT invoking the wire, so the fail-fast
  error cannot feed the breaker.
- **Timeout**: implemented per call via a bounded future wait around the
  wire exchange inside the clients; on expiry the call error is `timeout`.
  Timeouts count as breaker failures (they are call errors per the issue)
  but are never retried.
- **Retry**: opt-in via `McpCallOptions.retry` and only when
  `options.readOnly` is true; transient = thrown wire exceptions or call
  errors coded `transport-error`/`unavailable`/`server-error`; bounded
  attempts with an injected backoff delay (house pattern — no real sleeps
  in tests).
- **Per-server**: one guard per client instance, constructed from an
  optional `McpBreakerConfig` (threshold, cooldown — defaults 5 / 30s).

## Files

```text
lib/src/mcp/mcp_call_guard.dart        # NEW: guard + configs + options
lib/src/mcp/mcp_client.dart            # EDIT: options param + contract docs
lib/src/mcp/mcp_tool_descriptor.dart   # EDIT: additive readOnly flag
lib/src/mcp/sse_mcp_client.dart        # EDIT: guard/timeout/retry wiring
lib/src/mcp/stdio_mcp_client.dart      # EDIT: same
lib/src/mcp/in_proc_mcp_client.dart    # EDIT: options pass-through
test/mcp/mcp_call_guard_test.dart      # NEW: pure guard behaviors
test/mcp/mcp_120_resilience_test.dart  # NEW: client-level behaviors
```

## Constitution Check

I (pipeline) / V (gates) / X (pristine analysis) PASS; VII PASS (no new
dart:io); the immutable breaker is reused, not duplicated. Baseline: 1240
passed / 0 failed, analyzer clean.

## Sequencing

tdd.plan → tdd.run (guard units → timeout → retry → breaker-through-client →
acceptances) → tdd.verify → PR (closes #120).
