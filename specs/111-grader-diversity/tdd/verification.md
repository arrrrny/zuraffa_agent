---
feature: 111-grader-diversity
verified_at: "(post-cycle HEAD, branch 111-grader-diversity)"
suite: "1288 passed, 0 failed, ~2 skipped"
analyzer: "No issues found!"
purity_gate: "PASS (graders are pure; dart:convert only)"
behaviors_total: 11
behaviors_done: 11
test_after: 0
high_smells: 0
med_smells: 0
low_smells: 0
audit_mutants: "1 run — unknown-id mis-resolution mutant KILLED by U8"
standard: "speckit-tdd-verify skill text + house precedent"
independence: "loop-authored audit"
---

# TDD Verification: Grader diversity (spec 111)

## Verdict

**PASS** — all 11 behaviors DONE with compile-error red evidence per cycle;
each grader family has positive AND negative fixtures; a real
implementation bug (replaceAll does not expand `$1` capture groups) was
caught by U3 during the cycle; the registry's binding guarantee is
mutant-verified; gates green.

## Test-first evidence

| Classification | Count | Behaviors |
|---|---|---|
| LIKELY (compile-error red + same-commit green) | 9 | U1–U9 |
| Composed acceptance | 1 | A1 (four families through the registry) |
| Mechanical gates | 1 | A2 |
| TEST_AFTER / NO_TEST | 0 | — |

## Findings

- In-cycle fix (recorded): `String.replaceAll` does not substitute `$1` —
  `replaceAllMapped` used for index tokens. Caught by U3's positive
  fixture, not by inspection.
- Interface `grade` made async during cycle 1 so the llm-judge grader
  implements the interface directly (the issue's "common interface"
  requirement).

## Traceability

| Criterion | Behaviors | Evidence |
|---|---|---|
| SC-001 | U1 | exact fixtures |
| SC-002 | U2 | regex fixtures |
| SC-003 | U3, U4 | json-path fixtures (pass / missing / mismatch / malformed) |
| SC-004 | U5–U7 | judge PASS / FAIL / unparsable with scripted seam |
| SC-005 | A1 ← U8, U9 | registry binding + bulk evaluation |
| SC-006 | A2 | analyze clean, suite green, purity PASS |

## What was not audited

- Full JSONPath grammar (documented subset only: `$`, dot keys, integer
  indices).
- Live LLM judge behavior (scripted seam; no network).
- Golden-mission corpus integration (separate issue).
- The audit was loop-authored, not an independent session.
