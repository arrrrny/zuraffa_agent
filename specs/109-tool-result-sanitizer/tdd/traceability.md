# Traceability: 109-tool-result-sanitizer

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:cc185702a2fe8030785f023dbc61c9975d9db6c4205a093b00dce61be91b6555
statements: 10
automated: 10
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 55 | 1. **Given** each default redaction rule and a result containing a realistic secret, **When** the mission sanitizes its tool output, **Then** the transcript carries the marker (`[REDACTED:<rule>]`) and the original substring is absent. | A1 | automated |
| AC-2 | 67 | 2. **Given** a benign corpus (including strings that resemble but do not match the patterns, e.g. `AKIA` in prose without the full key shape), **When** it is sanitized, **Then** it round-trips unchanged with zero matched rules. | A2 | automated |
| AC-3 | 79 | 3. **Given** a disabled rule, a custom pattern, and a custom marker template (e.g. `<REMOVED:{rule}>`), **When** sanitization runs, **Then** the disabled rule leaves its secret intact, the custom pattern fires with its own rule name, and the custom marker template is honored. | A3 | automated |
| AC-4 | 92 | 4. **Given** a mission whose tool returns secret-bearing content, **When** it runs with the sanitizer injected and without it, **Then** the sanitized run produces a redacted transcript and the unsanitized run produces a byte-identical transcript. | A4 | automated |
| FR-001 | 97 | - **FR-001**: the sanitizer exposes a `sanitize(content)` operation | U1 | automated |
| FR-002 | 100 | - **FR-002**: default rules cover: AWS access key ids, GitHub | U6 | automated |
| FR-003 | 105 | - **FR-003**: non-matching content round-trips unchanged with an | U7 | automated |
| FR-004 | 108 | - **FR-004**: per-rule enable/disable, custom patterns (name + | U8 | automated |
| FR-005 | 111 | - **FR-005**: `MissionRunner` accepts an optional sanitizer and | U10 | automated |
| FR-006 | 115 | - **FR-006**: the sanitizer is pure (no I/O) and deterministic. | U6 | automated |

