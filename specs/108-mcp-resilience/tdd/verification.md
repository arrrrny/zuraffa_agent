---
feature: 108-mcp-resilience
verified_at: "(post-cycle HEAD, branch 108-mcp-resilience)"
suite: "1257 passed, 0 failed, ~2 skipped"
analyzer: "No issues found!"
purity_gate: "PASS (no dart:io in mcp_call_guard.dart)"
behaviors_total: 14
behaviors_done: 14
test_after: 0
high_smells: 0
med_smells: 0
low_smells: 0
audit_mutants: "2 attempts — 1 no-op (pattern mismatch, nothing tested), 1 applied and KILLED by U1"
standard: "speckit-tdd-verify skill text + house precedent"
independence: "loop-authored audit"
---

# TDD Verification: MCP resilience — breaker, timeout, retry (spec 108)

## Verdict

**PASS** — all 14 behaviors DONE with recorded red evidence; the breaker's
core guarantee is mutant-verified (a guard that stops recording failures is
caught by U1); timeout, retry scoping, and pass-through behaviors are pinned
hermetically; gates green.

## Test-first evidence

| Classification | Count | Behaviors |
|---|---|---|
| LIKELY (compile-error red + same-commit green) | 12 | U1–U5 (guard file missing), U6–U12 (options/breakerConfig params missing) |
| Mechanical gates | 2 | A1 (breaker sequence through client, in-suite), A2 (analyze/test/purity/contract grep) |
| TEST_AFTER / NO_TEST | 0 | — |

## Existing-test changes

- Three `McpClient` test fakes (`mcp_082_resilience_test.dart`,
  `mcp_tool_adapter_test.dart`, `tool_listing_cache_test.dart`) gained the
  additive `options` parameter — compile-fix ripple of the interface change,
  no assertion touched. No weakened existing tests.

## Findings

- None HIGH/MED. LOW (recorded): the first audit-mutant attempt was a no-op
  (stale pattern vs formatted source) — re-run with an applied mutant; the
  timeout error for `_callWithReconnect` is produced via
  `.timeout()` + `on TimeoutException` because the wire-response future
  cannot synthesize a call-error value (documented in code).

## Traceability

| Criterion | Behaviors | Evidence |
|---|---|---|
| SC-001 | U6, U7, U10 | hung-wire timeout + default + never-retried |
| SC-002 | A1 ← U1–U5, U-breaker/U-breaker-reset | threshold/open/fail-fast/probe/reset through the client |
| SC-003 | U8, U9, U11 | retry scoping (read-only-only, transient-only, bounded) |
| SC-004 | A2 grep | McpClient contract names timeout/breaker/retry |
| SC-005 | A2 gates | analyze clean, suite green, purity PASS |

## What was not audited

- Live-server behavior (hermetic fakes only, per the house pattern).
- Half-open probe concurrency; per-tool breakers (out of scope).
- Mutation sampled (1 applied mutant + 10 in-cycle across the session), not
  exhaustive.
- The audit was loop-authored, not an independent session.
