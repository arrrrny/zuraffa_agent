---
feature: 012-agent-hooks-pipeline
verdict: PASS_WITH_GAPS
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 36c5123 # short SHA audited
behaviors: 17
proven: 17
likely: 0
test_after: 0
no_test: 0
high_smells: 0
criteria_total: 8
criteria_covered: 8
mutation_score: 100 # deliberate-mutant sampling: 4/4 killed (fold drop, abort identity, deny drop, retry inversion)
mutants_survived: 0
suite: 503 passed, 6 failed (all 6 pre-date the feature: unrelated loading failures), 27s
---

# TDD Verification: Agent Hooks Pipeline

**Verdict: PASS_WITH_GAPS.** All eight acceptance criteria are covered — the
nine lifecycle points through a scripted mission driver that plays the
engine role (spec 002 owns the real wiring), chaining/abort/deny/retry
through the pipeline's public API. Every behavior saw a genuine red: both
new modules landed as whole-file loading/compile reds with the behaviors
asserted individually inside them, and the pipeline module went green only
after its full fold/abort/deny/retry semantics existed. All four deliberate
mutants were killed. The gap is narrow and structural: the two modules'
behaviors share their loading reds (module-granular, not
per-behavior-granular reds), and the driver-based acceptance layer depends
on the same module greens rather than its own independent reds.

## Test-first evidence

| Behavior | Class      | Evidence |
| -------- | ---------- | -------- |
| U1-U3    | PROVEN     | 41-error compile red (value module missing); `c37a625` |
| U4-U12   | PROVEN     | 28-error compile red (pipeline module missing); fixture repairs (callback-hook naming, const scoping) were test-side and pre-green |
| A1-A5    | PROVEN*    | same loading red as U4-U12; *the driver plays the engine — the real engine integration is spec 002's scope, documented in plan + spec Assumptions |

## Findings

| # | Severity | Finding | Evidence |
| - | -------- | ------- | -------- |
| 1 | LOW | Red granularity is module-level (two big loading reds) rather than per-behavior; behaviors were asserted individually within each green run | cycle log cycles 1-3 |
| 2 | LOW | Engine-visible effects (modified request reaches the LlmClient, retry loop, deny short-circuit) are proven through the test driver, not the real engine loop (spec 002 boundary) | plan §Realistic Boundaries |

## Mutation testing summary

| Mutant | Applied to | Result |
| ------ | ---------- | ------ |
| fold drops the modify result (beforeModelCall) | pipeline fold | KILLED (+11 -3) |
| abort throws with wrong hook identity | _abort | KILLED (+12 -2) |
| deny branch dropped (falls through to proceed) | beforeToolCall | KILLED (+12 -2) |
| retry flag inverted (true→false / false→true) | afterModelCall | KILLED (+9 -5) |

## Gates

- `dart analyze` — 111 issues, all pre-existing (baseline at branch point:
  111); zero in spec-012 files (10 transient style infos fixed pre-delivery).
- `dart test` — +503 / -6; baseline +486 / -6; delta: +17 new passing,
  0 new failing.
- Constitution VII — no `dart:io`; VIII — dart_agent_core-lineage headers
  on both new files; hand-curated plain-Dart precedent documented in the
  value-layer header (embeds non-Zorphy engine types).

## Remediation

- T013: when spec 002 wires the pipeline into the engine loop, port the
  driver's semantics (pipeline-returned request → LlmClient; deny →
  synthetic ToolResultMessage; retry → re-generate; HookAbortError →
  engine stop outcome) and retire the driver's engine-role duplication.
