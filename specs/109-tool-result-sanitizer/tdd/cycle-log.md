# TDD Cycle Log: Tool-result sanitization (spec 109)

## Baseline

- **planned_at**: 2026-09-09, branch `109-tool-result-sanitizer` (off post-#144 master)
- **suite**: 1257 passed, 0 failed, ~2 skipped; analyzer clean
- **misfire protocol**: user-authorized report-and-continue (same as 105–108).

## Cycle 1 — the sanitizer (U1–U8)

### RED

```
$ dart test test/security/
  Failed to load ... 16 compile errors (tool_result_sanitizer.dart absent)
```

### GREEN

Interface + `SanitizedToolResult(content, matchedRules)` + `SanitizerConfig`
(disabled rules / custom patterns / marker template) + the six built-in
regex rules. In-cycle mechanics fixes: a miscounted space in U1's context
assertion; helper-class ordering/const issues from the first write.

```
$ dart test test/security/ → 8 passed; analyze clean
```

## Cycle 2 — runner wiring (U9, U9b, U10, A1)

### RED

```
$ dart test test/engine/mission_runner_sanitizer_test.dart
  Error: No named parameter with the name 'toolResultSanitizer'.
```

(Several test-side compile fixes first: ToolCall's real shape has
`executionMode`, `ToolCallPlanner` is an interface so the planner became a
ScriptedPlanner class, closure returns typed.)

### GREEN

Optional `toolResultSanitizer` on `MissionRunner`; the dispatched tool's
content (success and error) is sanitized right before the transcript join.

```
$ dart test  → 1268 passed / 0 failed; dart analyze → No issues found!
```

## Audit mutant (post-cycle)

```
MUTANT: sanitizer bypassed at the transcript join
U9: a secret-bearing tool result joins the transcript redacted [E]
  Actual: 'failed reading AKIA…EXAMPLE (fixture)'
U9b: error text is sanitized too [E]
```

Both wiring tests catch the bypass. Restored exactly; suite green; analyze
clean.

## Baseline note

Two analyzer infos (curly-braces lint in circuit_breaker/steering_queue
serialization) were inherited from master via the owner's 0.3.1 formatter-
pass commit (2e16eb0), which landed mid-run. Fixed as trivial baseline
cleanup so the feature's gates stay pristine — flagged here per
constitution X discipline.
