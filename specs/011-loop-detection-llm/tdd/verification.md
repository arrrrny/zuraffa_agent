---
feature: 011-loop-detection-llm
verdict: PASS_WITH_GAPS
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 913e796 # short SHA audited
behaviors: 17
proven: 14
likely: 0
test_after: 3
no_test: 0
high_smells: 0
criteria_total: 6
criteria_covered: 6
mutation_score: 100 # deliberate-mutant sampling: 4/4 killed (M4 needed a test strengthening first — the surviving-mutant catch)
mutants_survived: 0
suite: 486 passed, 6 failed (all 6 pre-date the feature: unrelated loading failures), 26s
---

# TDD Verification: Loop Detection (LLM-based)

**Verdict: PASS_WITH_GAPS.** All six acceptance criteria are covered through
the detector's public `observe()` API, fourteen of seventeen behaviors had
genuine reds (whole-file loading reds for both new modules — the behaviors
were asserted individually within them), and the run caught one real
implementation bug (first-diagnosis boundary) whose test now pins it. All
four deliberate mutants were killed — one only after its survival exposed a
test gap (U11 covered one malformed shape but not the `is! Map` branch),
which was closed with three malformed-shape cases.

## Test-first evidence

| Behavior | Class      | Evidence |
| -------- | ---------- | -------- |
| U1-U3    | PROVEN     | compile-red (value layer file missing); `d98320e` |
| U4-U8    | PROVEN     | compile-red (detector file missing), first run +11 -3 → U6 test-arithmetic repair + U9/U11 impl-bug fix (first-check boundary) |
| U9       | PROVEN*    | red was a genuine implementation bug (first diagnosis gated on interval), fixed → green; *the bug was in the just-written impl, not pre-existing |
| U10      | PROVEN     | boundary case (verdict exactly 0.8) held through the `>=`→`>` mutant |
| U11      | PROVEN     | red via the same boundary bug; then strengthened after M4 survived; three malformed shapes pinned |
| A1-A3    | TEST_AFTER | first-ran green over the already-green detector units (same loading red as U4-U8) |
| A4-A6    | TEST_AFTER | first-ran green; A4/A5 re-prove U8/U9 at spec-default settings (30 turns), A6 is the SC-003 false-positive sweep |

## Findings

| # | Severity | Finding | Evidence |
| - | -------- | ------- | -------- |
| 1 | MED | First green run shipped a real boundary bug: first diagnosis was gated by llmCheckInterval from turn 0, delaying the first check when llmCheckAfterTurns < interval | cycle log cycle 2-4; U9 red |
| 2 | LOW | M4 (non-object JSON → stagnant) initially survived: U11 only exercised the FormatException path; closed by adding JSON-array and wrong-typed-field shapes | mutation log |
| 3 | LOW | A-layer behaviors first-ran green (outside-in over green units); compensated by unit reds + mutants | cycle log |

## Mutation testing summary

| Mutant | Applied to | Result |
| ------ | ---------- | ------ |
| streak never resets (different signature ignored) | observe() streak branch | KILLED (+12 -2) |
| key-order-sensitive signature (raw jsonEncode) | toolCallSignature | KILLED (+2 -1) |
| confidence `>=` → `>` | stagnation comparison | KILLED (+13 -1) |
| non-object JSON verdict treated as stagnant | _diagnose `is! Map` branch | KILLED after U11 strengthening (+13 -1); SURVIVED once before |

## Gates

- `dart analyze` — 111 issues, all pre-existing (baseline at branch point:
  111); zero in spec-011 files.
- `dart test` — +486 / -6; baseline +469 / -6; delta: +17 new passing,
  0 new failing.
- Constitution VII — no `dart:io`; VIII — dart_agent_core-lineage headers
  on both new files.

## Remediation

- T012: none open. (Spec 002 will wire observe() into the engine loop and
  translate detections into the LoopDetected safety-rail outcome.)
