# Implementation Plan: Tool-result sanitization (issue #118)

**Branch**: `109-tool-result-sanitizer` | **Date**: 2026-09-09 | **Spec**: [spec.md](./spec.md)

## Summary

`lib/src/security/tool_result_sanitizer.dart`: `ToolResultSanitizer`
interface (`sanitize → SanitizedToolResult(content, matchedRules)`),
`SanitizerConfig` (disabled rule names, custom patterns, marker template
with `{rule}`), and `RegexToolResultSanitizer` with six built-in rules.
`MissionRunner` gains an optional `toolResultSanitizer` applied where a
dispatched tool's output joins the transcript (success content and error
text). Pure Dart; no dart:io; no new dependencies.

## Built-in rules (name → pattern shape)

| rule | matches |
|---|---|
| `aws-access-key-id` | `AKIA[0-9A-Z]{16}` |
| `github-pat` | `gh[pousr]_[A-Za-z0-9]{36,}` |
| `jwt` | `eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+` |
| `private-key-header` | `-----BEGIN [A-Z ]*PRIVATE KEY-----` |
| `slack-token` | `xox[abprs]-[A-Za-z0-9-]{10,}` |
| `stripe-live-key` | `[sr]k_live_[A-Za-z0-9]{20,}` |

Default marker: `[REDACTED:{rule}]`. Config: `disabledRules` (set),
`customPatterns` (name → RegExp), `markerTemplate`.

## Constitution Check

I/V/X PASS; VII PASS (pure file); VIII n/a; IX n/a (no model classes —
config is a plain value object per the 081/104 precedent, header recorded).

## Files

```text
lib/src/security/tool_result_sanitizer.dart   # NEW
lib/src/engine/mission_runner.dart            # EDIT: optional sanitizer at the transcript join
test/security/tool_result_sanitizer_test.dart # NEW (U1–U8, SC-001..003)
test/engine/mission_runner_sanitizer_test.dart# NEW (U9, U10, A1/SC-004)
```

## Sequencing

tdd.plan → tdd.run (U1–U8 → U9–U10 → acceptances) → tdd.verify → PR (closes #118).
