# Test List: Eval Suite Health & Release Gate (spec 085)

---
feature: 085-eval-suite-health
loop: outside-in
profile: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md
spec_criteria: 10 # FR-001..FR-010 in spec.md
planned_at: master (29b7fef)
updated_at: 085-eval-suite-health
suite_baseline: green # 1073 passed / 2 skipped at 29b7fef
---

## Outer loop: acceptance behaviors

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| A1  | The gate is trustworthy in the corners: an empty suite fails closed, a zero-run task vetoes instead of crashing, and the veto is machine-readable | FR-005, FR-006, FR-007, SC-001..SC-003 | example | PLANNED | `test/eval/suite_gate_085_test.dart` (T1–T4) |
| A2  | Gates: `dart analyze` clean vs baseline; full `dart test` green including the unmodified spec-006 `suite_gate_006_a4_test.dart` | FR-010 | gate | PLANNED | gates at branch HEAD (counts in verification.md) |

## Inner loop: unit behaviors

### New surface (RED)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U1  | Zero-task suite at threshold 0.0 → `passed == false`, `exitCode == 1`, report names the fail-closed reason | FR-007 | unit | PLANNED | T1 |
| U2  | `TaskSamples(n: 0)` → no throw; task scores 0.0 with zero-runs detail; gate vetoed | FR-005 | unit | PLANNED | T2 |
| U3  | Mixed missing + zero-run → `incomplete == true`, `incompleteTaskIds` in suite order; complete suite → false/empty | FR-006 | unit | PLANNED | T3 |

### Pins (existing behavior, previously unguarded at these edges)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U4  | All tasks missing → fail, all ids listed, score 0.0 | FR-004, FR-008 | pin | PLANNED | T4 |
| U5  | `>=` boundary: score exactly at threshold passes | FR-003 | pin | PLANNED | T5 |
| U6  | Unbiased per-task value pass-through: `n: 10, c: 4, k: 1` → 0.4 in the breakdown | FR-001 | pin | PLANNED | T6 |
| U7  | Extra sample ids not declared by the suite are ignored (score over declared tasks only) | FR-002 | pin | PLANNED | T7 |
| U8  | `c > n` still throws `ArgumentError` (invalid arithmetic ≠ incomplete run) | FR-009 | pin | PLANNED | T8 |

> **Pin honesty**: U4–U8 pin behavior that ships on master (006-A4 covers
> the core veto/boundary; 037 covers the estimator). The genuinely new
> behavior — fail-closed empty suites, zero-run veto, machine-readable
> veto — is RED-first (U1–U3).

## Edge cases & invariants

- Threshold 0.0 with zero tasks — the fail-open case this spec closes.
- `n == 0` with `c == 0` — zero-run veto; `n == 0, c > 0` impossible
  (`c > n` → ArgumentError, T8's contract).
- Veto order equals the suite's declared task order.
- Existing report lines byte-identical (006-A4 asserts on them).
- Pure function: same inputs → same decision (no clock/randomness/IO).

## Out of scope

- Sample production (harness/runner — specs 006/061).
- PassAtK estimator changes (spec 037).
- Suite configuration schema; report formatting beyond the new reason
  line.
- Spec-006's own A4 tests (kept unmodified as the regression guard).

## Verification commands

```bash
dart analyze
dart test test/eval/suite_gate_085_test.dart
dart test test/eval/suite_gate_006_a4_test.dart
dart test
```
