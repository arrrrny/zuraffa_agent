---
feature: 018-engine-event-provider-error
verdict: PASS_WITH_FINDINGS
standard: .specify/memory/tdd-profile.md # referenced by sibling 023; file absent at HEAD — the profile's intrinsic rules (as evidenced by the 023 artifact) + constitution.md Principles II/V/X applied
verified_at: HEAD of feat/spec-018-engine-event-provider-error # working tree; commit SHA recorded in PR
behaviors: 8
proven: 3
likely: 0
test_after: 5
no_test: 0
high_smells: 0
criteria_total: 4
criteria_covered: 4
mutation_score: 75 # deliberate-mutant sampling (no mutation tool installed): 3 of 4 meaningful mutants killed; 1 documented survivor (M4, same class of survivor as specs 016/017)
mutants_survived: 1
suite: 912 passed, 0 failed, 2 skipped # vs baseline 911 passed / 2 skipped at 30b4b94 — +1 new test, 0 new failures; skips are pre-existing KIMI_API_KEY integration tests
---

# TDD Verification: EngineEvent.ProviderError

**Verdict: PASS WITH FINDINGS.** The `ProviderError` class itself landed
on master via PR #40 (closed issue #18) **before** this TDD pass ran —
the red phase for the class-level behaviors therefore could not be
replayed against a class-less tree, and those behaviors are graded
TEST_AFTER relative to the merged work (same grading applied by sibling
spec 023 to its gate-level behaviors). This cycle closes what actually
remained: the spec-kit TDD artifacts did not exist, the
`describe(EngineEvent)` routing for `ProviderError` was never asserted,
and every pre-existing test constructed `providerName` and `error` as
the identical string `'sample'`, leaving a string cross-binding defect
undetectable. One new test was added test-first (backed by genuine
mutation kills) and the payload test was strengthened with distinct
values. Three deliberate mutants were killed; one honest survivor is
documented (same class of survivor as specs 016/017). All four
acceptance criteria are covered. No HIGH test smells were found.

## Test-first evidence

| Behavior | Class | Evidence |
| -------- | ----- | -------- |
| A1 | TEST_AFTER | `…::ProviderError is an EngineEvent` — landed with #40; no red replayable (class merged before this pass); re-verified green this cycle. |
| A2 | PROVEN | `…::ProviderError carries payload fields` — strengthened this cycle: `providerName` (`'openai'`) and `error` (`'401 unauthorized (terminal)'`) are now distinct values, each asserted against its own field. Mutant M2 kills this. |
| A3 | TEST_AFTER (gate) | `dart analyze --fatal-infos` — exit 0, "No issues found!" at branch HEAD. Mutant M3 proves the gate bites. |
| A4 | TEST_AFTER (gate) | `dart test` — exit 0, `+912 ~2: All tests passed!` (baseline 911/2 at `30b4b94`; delta = +1 new test, 0 new failures). |
| U1 | PROVEN | payload-shape check — mutant M1 (drop `error`) is killed by compile error `No named parameter with the name 'error'` (3 sites), test exit 1. |
| U2 | PROVEN | distinct-values cross-binding check — mutant M2 is killed: `Expected: 'openai' / Actual: '401 unauthorized (terminal)'`, exit 1. |
| U3 | TEST_AFTER (gate) | `part 'provider_error.dart';` directive — mutant M3 (directive removed) fails both gates: analyze exit 3 (`Undefined class 'ProviderError'`), `dart test` exit 1 (`Some tests failed.`). |
| U4 | TEST_AFTER | `…::describe(EngineEvent) switch routes ProviderError to provider_error(providerName)` — the shared #24 group switch already carried the arm (landed with #40); this new test asserts its output AND that the routing keys on `providerName` (`provider_error(openai)`), not on `error`. Killed transitively under M2/M3 mutations. |

## Findings

| # | Severity | Finding | Evidence |
| - | -------- | ------- | -------- |
| 1 | LOW | The class landed (merged PR #40) before this TDD pass, so class-level red evidence is not replayable; those behaviors are TEST_AFTER per the 023 precedent, with mutation proof substituted. | PR #40 |
| 2 | LOW | Mutant M4 (drop `final` from `class ProviderError`) **survived**: analyze exit 0, `+3: All tests passed!` — identical to specs 016/017's findings. The `final`/`base`/`mixin` restriction for sealed subtypes applies only OUTSIDE the declaring library; part files are inside it. Runtime tests cannot observe finality; only a custom lint would catch its removal. | M4 run log (below) |
| 3 | LOW | The auditor is the same session that authored the artifacts — the audit is not independent (rubric Hard Rule 2 requires stating this). | this file |

No existing tests were weakened, skipped, or filtered: the #18 group's
payload test was strengthened (distinct string values) and one test was
added; the is-A test is untouched; no other group was modified.

## Mutation results

No mutation tool is installed for this stack, so test strength was
measured by deliberate mutants — one at a time, each restored and the
suite re-run green afterwards. 4 meaningful mutants, 3 killed, 1
survivor:

| Mutant | Behavior | Survived | Judgment |
| ------ | -------- | -------- | -------- |
| M1 — drop `error` field + its constructor param from `provider_error.dart` | U1 / A2 | No | caught — compile error `Error: No named parameter with the name 'error'` (3 call sites), `dart test` exit 1, `+0 -1: Some tests failed.` |
| M2 — initializer-list cross-binding: `this.providerName = error, this.error = providerName` | U2 / A2 | No | caught — `Expected: 'openai' / Actual: '401 unauthorized (terminal)'`, exit 1, `+0 -1: Some tests failed.` |
| M3 — remove `part 'provider_error.dart';` from `engine_event.dart` | U3 / A3 | No | caught — `dart analyze --fatal-infos` exit 3, `Undefined class 'ProviderError'` at the shared switch and the #18 group; `dart test` exit 1. |
| M4 — replace `final class ProviderError` with `class ProviderError` | A1 (class shape) | **Yes** | survived — analyze exit 0 ("No issues found!"), `+3: All tests passed!`. Same class of survivor as specs 016/017; declaration-level, not behavioral. |

Sampling, not exhaustive: mutants targeted the highest-risk behaviors
(the diagnostic payload, string cross-binding between provider identity
and failure text, the part-file wiring).

## Traceability

| Criterion | Tests | End to end (public API) |
| --------- | ----- | ----------------------- |
| SC-001 — `dart analyze --fatal-infos` exits 0 | A3, U3 (mutant M3) | Yes — verified at branch HEAD, exit 0 |
| SC-002 — `dart test` passes all baseline + new tests | A1, A2, A4, U4 | Yes — 912 passed / 2 pre-existing skips, 0 failed |
| FR-001 — `final class ProviderError extends EngineEvent` with `emittedAt/providerName/error` | A1, A2, U1, U2 | Yes |
| FR-002 — `part 'provider_error.dart';` directive | U3 | Yes |
| FR-003 — `describe(EngineEvent)` switch handles `ProviderError` | U4 | Yes — routing asserted: `provider_error(openai)` (keys on `providerName`, not `error`) |
| FR-004 — `dart analyze --fatal-infos` + `dart test` pass | A3, A4 | Yes |

Untested criteria: none. Tests tracing to nothing: none.

## What was not audited

- Mutation coverage is a 4-mutant sample, not an exhaustive run — no Dart mutation tool exists in the repo.
- Coverage was not measured: `dart test --coverage` emits VM traces but `package:coverage` is not installed and adding deps mid-loop is forbidden.
- Emission of `ProviderError` by the fallback-chain runtime (spec-004 / spec-008) is out of scope, as is any retry/fallback behavior it triggers.
- `.specify/memory/tdd-profile.md` (referenced by sibling 023) does not exist at HEAD; the 023 artifact was used as the de-facto rubric template.
- The audit was performed by the same session that authored the artifacts (finding #3).

## Remediation tasks

None blocking. Finding #2 (M4 survivor) is the same declaration-level
gap recorded for specs 016 and 017 — a single repo-level custom lint
requiring `final`/`base` on sealed-subtype declarations would close all
three; tracked as a follow-up candidate, out of scope for this spec.
