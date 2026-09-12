# Spec refinement — latest zfa template conformance (2026-09-11)

All 97 spec directories now pass `zfa tdd plan` under zfa v6.2.2's
current gates (verified per-feature; previously 33/92 failed).

## What was refined

1. **Numbered acceptance scenarios (105–111)**: the recent-batch specs
   carried `**Acceptance**:` prose instead of the numbered
   `N. **Given** ... **When** ... **Then** ...` blocks the plan gate
   derives acceptance behaviors from. Each user story's prose was
   converted to a numbered scenario (behavior preserved verbatim).

2. **Unit-lane contract traces (52 legacy specs)**: the current plan
   refuses unit behaviors that "carry no declared contract trace"
   (issue #1480: the unit lane can never self-heal). Each functional
   requirement now carries a `traces: <Component>.fr<N>` line resolved
   by a mechanically-declared `## Layer Contracts` row set
   (`<Component>` = the spec's primary component, derived from its
   Files section). For historical specs these rows are routing
   metadata, not new API surface — the features shipped long ago and
   their behavioral coverage lives in their (green) test suites.

## What was NOT changed

- FR prose, acceptance prose, scenarios, summaries, file lists — only
  formatting normalization (`- **FR-001** (US1):` → `- **FR-001**:`),
  the `traces:` lines, and the Layer Contracts sections.
- Specs authored this session (112–116) already adhered and were not
  touched by the bulk pass.
