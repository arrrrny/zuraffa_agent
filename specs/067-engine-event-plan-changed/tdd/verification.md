---
feature: 067-engine-event-plan-changed
verdict: PASS_WITH_FINDINGS
standard: .specify/memory/tdd-profile.md # referenced by sibling 023; file absent at HEAD — 023 artifact as de-facto rubric + constitution.md Principles II/V/X
verified_at: HEAD of feat/spec-067-engine-event-plan-changed # working tree; commit SHA recorded in PR
behaviors: 9 # A1-A5, U1-U4
proven: 7
likely: 0
test_after: 2 # A5 gates + U2 compile gate
no_test: 0
high_smells: 0
criteria_total: 5
criteria_covered: 5
mutation_score: 67 # deliberate-mutant sampling: 4 of 6 runs killed (1 invalid mutant excluded, 1 documented survivor)
mutants_survived: 1
suite: 915 passed, 0 failed, 2 skipped # baseline 911/2 at 30b4b94 + 4 new tests; skips are pre-existing KIMI_API_KEY integration tests
---

# TDD Verification: EngineEvent.PlanChanged

**Verdict: PASS WITH FINDINGS.** Genuinely test-first: the spec-067 test
group and the shared-switch arm were written and run BEFORE the part file
existed — RED was the house-style `'PlanChanged' isn't a type` compile
failure (8 sites, exit 1), exactly the red 023 documented for new union
members. The 10th member of the sealed union now exists, closing the
wiring gap spec 014 FR-005 left open (the domain `PlanChangedEvent`
landed but could not join the union from outside its declaring library).
Four deliberate mutants killed; one contract-legal survivor documented;
one invalid (non-compiling) mutant honestly excluded and re-designed.

## Test-first evidence

| Behavior | Class | Evidence |
| -------- | ----- | -------- |
| A1 | PROVEN | RED: `Error: 'PlanChanged' isn't a type` (exit 1). GREEN: `PlanChanged is an EngineEvent` passes; `+26: All tests passed!` for the file. |
| A2 | PROVEN | payload test asserts `identical(event.change, c)`, `same(previous)`, `same(next)`, and `change.emittedAt != event.emittedAt` (the two instants are distinct by design). |
| A3 | PROVEN | `describe(EngineEvent)` routes to `plan_changed(p-2)` — asserted in both the shared `#24` switch and the spec-067 group's own switch. |
| A4 | PROVEN | value semantics: equal events `==` and hash equal; varying `emittedAt` OR `change` ⇒ unequal; exact `toString` (full deterministic nested render with empty-plan `PlanState`s). Killed by mutants M2/M4. |
| A5 | TEST_AFTER (gate) | `dart analyze --fatal-infos` exit 0, "No issues found!"; `dart test` exit 0, `+915 ~2: All tests passed!` (baseline 911/2 + 4). |
| U1 | PROVEN | mutant M1 (drop `change` field) killed by compile error at 3 construction sites. |
| U2 | TEST_AFTER (gate) | import + `part 'plan_changed.dart';` wiring — mutant M3 (directive removed) fails both gates. |
| U3 | TEST_AFTER | shared-switch arm — load-bearing for exhaustiveness: with the union grown, removing the arm is a compile error (the compiler enforces FR-003's exhaustiveness; not separately mutated — the arm's ROUTING is asserted by A3). |
| U4 | PROVEN | mutants M2 (== drops `change`) and M4 (identityHashCode) both killed. |

## Findings

| # | Severity | Finding | Evidence |
| - | -------- | ------- | -------- |
| 1 | LOW | Mutant M5 (hashCode ignores `change`: `Object.hash(emittedAt, emittedAt)`) **survived** — exit 0, `+4: All tests passed!`. Contract-legal: Dart requires only equal objects ⇒ equal hashCodes; hash quality is not observable behavior. Same class as spec 066's M4 survivor. | M5 re-run log |
| 2 | LOW | Mutant M5's first formulation (`Object.hash(emittedAt)`) was **invalid**: Dart 3.11's `Object.hash` requires ≥ 2 positional arguments (`object1`, `object2` both required — verified against the SDK source), so the mutant failed to compile rather than testing behavior. Excluded from the score, redesigned as `Object.hash(emittedAt, emittedAt)`. Worth knowing for future mutant design on this stack. | /tmp/067_m5.txt + SDK `object.dart` |
| 3 | LOW | The auditor is the same session that authored the artifacts — the audit is not independent. | this file |

No existing tests were weakened, skipped, or filtered: the shared `#24`
switch gained one arm (required for exhaustiveness); the new group is
purely additive; all pre-existing groups pass unchanged.

## Mutation results

Deliberate mutants, one at a time, `cp`-backup restored, suite re-run
green after each (per spec 066's lesson: never `git checkout` uncommitted
work). 5 valid mutants, 4 killed, 1 survivor (+1 invalid excluded):

| Mutant | Behavior | Survived | Judgment |
| ------ | -------- | -------- | -------- |
| M1 — drop `change` field + constructor param | U1 / A2 | No | caught — `Error: No named parameter with the name 'change'` (3 sites), exit 1. |
| M2 — `==` drops the `change` comparison | A4 / U4 | No | caught — `Expected: not PlanChanged:<…next: PlanState(id: p-9…)> / Actual: PlanChanged:<…next: PlanState(id: p-2…)>`, exit 1 (readable via the new toString). |
| M3 — remove `part 'plan_changed.dart';` | U2 / A5 | No | caught — analyze exit 3 (12 errors incl. `extends_non_class`); `dart test` exit 1 (`'PlanChanged' isn't a type`). |
| M4 — `hashCode => identityHashCode(this)` | A4 / U4 | No | caught — `Expected: <549211514> / Actual: <1013193220>`, exit 1. |
| M5 — hashCode ignores `change` (`Object.hash(emittedAt, emittedAt)`) | A4 | **Yes** | survived — exit 0, `+4: All tests passed!`. Contract-legal hash-quality reduction; documented, not fixed. |

## Traceability

| Criterion | Tests | End to end (public API) |
| --------- | ----- | ----------------------- |
| FR-001 — `final class PlanChanged extends EngineEvent` with `emittedAt` + `change` | A1, A2, U1 + M1 | Yes |
| FR-002 — `part 'plan_changed.dart';` + domain import, no cycle | U2 + M3 | Yes — analyze clean proves acyclicity |
| FR-003 — exhaustive switch handles `PlanChanged` | A3, U3 | Yes — routing asserted: `plan_changed(p-2)` |
| FR-004 — value semantics at birth | A4, U4 + M2/M4 | Yes |
| FR-005 — analyze clean + full suite green | A5 | Yes — 915/0/2 at branch HEAD |

Untested criteria: none. Tests tracing to nothing: none.

## What was not audited

- Mutation coverage is a 5-valid-mutant sample, not exhaustive.
- Coverage tooling not installed (profile forbids mid-loop dep additions).
- The engine-loop runtime site that constructs/emits `PlanChanged` (epic #2 successor work) — out of scope.
- Interaction with open PRs #74–#76 (their describe switches will each need one `PlanChanged` arm on merge — noted in the PR body; inherent to growing a sealed union, same as PRs #40/#41/#42 before it).

## Remediation tasks

None blocking. Finding #1 is contract-legal; finding #2 is a mutant-design
note recorded for future cycles on this stack.
