**Template Version**: `zuraffa-1.0`

# Feature Specification: Tool-result sanitization before LLM egress

**Branch**: `109-tool-result-sanitizer` | **Date**: 2026-09-09

**Status**: Draft

**Input**: GitHub issue #118 — "Implement tool-output redaction/sanitization
before LLM egress". Severity: high (prompt-injection / secret-exfiltration
defense). 

## Summary

Tool results flow straight into the mission transcript and from there into
the next LLM request: a `read_file` of `~/.aws/credentials` would relay
credential material verbatim to the model vendor. This spec adds an
injectable `ToolResultSanitizer` with regex-based default rules (AWS key,
GitHub PAT, JWT, private-key headers, Slack token, Stripe live key),
configurable per rule, and wires it into `MissionRunner` at the point where
a dispatched tool's output joins the transcript — the egress boundary.

**Out of scope**: audit-log emission on redaction (the audit log itself is
issue-tracked separately — the sanitizer's result type carries the matched
rule names so a future audit hook can log without re-matching); input-side
(prompt) sanitization; binary content handling.

## Files

- `lib/src/security/tool_result_sanitizer.dart` — NEW: the interface, the
  `SanitizedToolResult` value (content + matched rule names), the
  `SanitizerConfig` value object (enabled rules, custom patterns, marker
  template), and the default regex implementation.
- `lib/src/engine/mission_runner.dart` — EDIT: optional
  `toolResultSanitizer`; applied to a dispatched tool's output (success
  content and error text) before it joins the transcript.
- `test/security/tool_result_sanitizer_test.dart`,
  `test/engine/mission_runner_sanitizer_test.dart` — NEW.
- `specs/109-tool-result-sanitizer/` — this artifact set.

## User scenarios

### US1 — Secrets never reach the vendor (P1)

As a security reviewer, a tool result containing a credential joins the
mission transcript redacted — each secret replaced by a marker naming the
rule that caught it — so the next LLM request carries no secret material.

**Acceptance**: for each default rule, a result containing a realistic
secret comes out of a sanitized mission with the marker
(`[REDACTED:<rule>]`) in the transcript and the original substring absent.

### US2 — Benign output is untouched (P1)

As a tool author, normal tool output (code, logs, paths, prose) passes
through byte-for-byte; no false positives.

**Acceptance**: a benign corpus (including strings that resemble but do not
match the patterns, e.g. `AKIA` in prose without the full key shape)
round-trips unchanged with zero matched rules.

### US3 — The defense is configurable (P2)

As an integrator, I can disable individual rules, add custom patterns with
their own names, and change the marker template.

**Acceptance**: a disabled rule leaves its secret intact; a custom pattern
fires with its own rule name; a custom marker template (e.g.
`<REMOVED:{rule}>`) is honored.

### US4 — The runner wires it at the egress boundary (P1)

As an integrator, injecting the sanitizer into the mission runner protects
every dispatched tool's output; without a sanitizer, behavior is exactly as
before.

**Acceptance**: a mission whose tool returns secret-bearing content
produces a redacted transcript when the sanitizer is injected, and a
byte-identical transcript when it is not.

## Requirements

### Functional requirements

- **FR-001** (US1): the sanitizer exposes a `sanitize(content)` operation
  returning the sanitized content plus the names of the rules that matched.
- **FR-002** (US1): default rules cover: AWS access key ids, GitHub
  personal access tokens, JWTs, private-key block headers, Slack tokens,
  and Stripe live keys — each redacting only the secret substring, leaving
  surrounding content intact.
- **FR-003** (US2): non-matching content round-trips unchanged with an
  empty matched-rule list.
- **FR-004** (US3): per-rule enable/disable, custom patterns (name +
  regex), and a marker template with a `{rule}` placeholder.
- **FR-005** (US4): `MissionRunner` accepts an optional sanitizer and
  applies it to dispatched tool output (success content and error text)
  before the transcript join; absent sanitizer = unchanged behavior.
- **FR-006**: the sanitizer is pure (no I/O) and deterministic.

## Success criteria

- **SC-001** (US1 / FR-001–002): every default rule's fixture redacts with
  the correct marker and the original secret substring is absent.
- **SC-002** (US2 / FR-003): the benign corpus round-trips unchanged.
- **SC-003** (US3 / FR-004): disable / custom-pattern / custom-marker all
  behave as configured.
- **SC-004** (US4 / FR-005): the composed mission transcript is redacted
  with the sanitizer and verbatim without it.
- **SC-005**: `dart analyze` pristine; suite green; purity gate unchanged.

## Assumptions

- Redaction replaces only the matched substring (context around a secret
  is useful to the model; the secret itself is not).
- Error text is sanitized the same as success content.
- The audit-log acceptance from the issue is deferred until the audit log
  exists; `SanitizedToolResult.matchedRules` is the forward-compatible hook.

## Dependencies

- Builds on: master (post-#144) — `MissionRunner`'s transcript join,
  `ToolDispatchResult`.
- Pairs with (out of scope): threat model (#130), audit log, input
  sanitization.
