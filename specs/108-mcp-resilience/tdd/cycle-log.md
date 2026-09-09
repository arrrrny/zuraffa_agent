# TDD Cycle Log: MCP resilience (spec 108)

Append-only record of the red-green-refactor cycles.

## Baseline

- **planned_at**: 2026-09-09, branch `108-mcp-resilience` (off post-#143 master)
- **suite**: 1240 passed, 0 failed, ~2 skipped
- **analyzer**: `No issues found!`
- **misfire protocol**: user-authorized report-and-continue (same as 105-107).

## Cycle 1 — the guard (U1–U5, U7 + config smoke)

### RED

```
$ dart test test/mcp/mcp_call_guard_test.dart
  Failed to load ... Error: Target of URI doesn't exist: mcp_call_guard.dart  (7 errors)
```

### GREEN

`McpCallGuard` (mutable holder over the immutable breaker, injectable clock)
+ `McpBreakerConfig` / `McpRetryConfig` / `McpCallOptions` (30s default).
In-cycle mechanics fixes: `recordSuccess()` has no `at:` param; test passed
`clock:` instead of `now:`; call thunks wrapped as `() => ...`.

```
$ dart test test/mcp/mcp_call_guard_test.dart → 7 passed; analyze clean
```

## Cycle 2 — client wiring (U6, U8–U12, A1)

### RED

```
$ dart test test/mcp/mcp_120_resilience_test.dart
  Error: No named parameter with the name 'options'.   (×4)
  Error: No named parameter with the name 'breakerConfig'.   (×2)
```

### GREEN

`McpClient.callTool` gains `{McpCallOptions? options}` (contract documents
timeout / breaker / retry); Sse + Stdio: guard + bounded
`.timeout(effectiveTimeout)` (TimeoutException → `timeout` error, never
retried) + read-only transient retry with injected backoff; InProc
pass-through; descriptor `readOnly` additive flag. Test-mechanics fixes
inside the cycle: the breaker-reset test was missing its fourth call; one
untyped list literal.

```
$ dart test  → 1257 passed / 0 failed; dart analyze → No issues found!
```

## Audit mutant (post-cycle)

First attempt was a NO-OP (mutation pattern didn't match the formatted
source — nothing was tested; recorded for honesty). Second attempt applied:

```
MUTANT: call errors no longer recorded by the guard
$ dart test test/mcp/mcp_call_guard_test.dart --plain-name "U1"
U1: N consecutive call errors open the guard [E]
```

Killed by U1; restored exactly; mcp suite 101 passed; analyzer clean.
