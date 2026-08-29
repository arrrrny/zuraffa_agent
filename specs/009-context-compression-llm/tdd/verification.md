---
feature: 009-context-compression-llm
verdict: FAIL
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # short SHA re-audited; regraded FAIL (prior PASS_WITH_GAPS violated rubric verdict table: any TEST_AFTER -> FAIL)
behaviors: 16
proven: 7
likely: 0
test_after: 9
no_test: 0
high_smells: 0
criteria_total: 5
criteria_covered: 5
mutation_score: 100 # deliberate-mutant sampling: 6/6 killed (one first mutant-application failure was caught and redone with an assertion)
mutants_survived: 0
suite: 453 passed, 6 failed (all 6 pre-date the feature: unrelated loading failures), 24s
---

# TDD Verification: Context Compression (LLM-based)

**Verdict: FAIL.** All five acceptance criteria are covered through the
compressor's public API, the SC-001 token budget and the SC-003 fallback are
pinned, and all six deliberate mutants were killed. But nine of sixteen
behaviors landed as first-run passes over implementations that arrived with
sibling cycles (the compressor core was built in three big greens: U3 gate, U4
path, U6 fallback), so their dedicated tests have mutant evidence but no genuine
reds — and the rubric's verdict table fails closed on *any* TEST_AFTER or
NO_TEST behavior. (The prior draft graded this PASS_WITH_GAPS; that contradicts
the rubric's FAIL condition and is corrected here for consistency with
specs 002/004/007/008.)

## Test-first evidence

| Behavior | Class      | Evidence |
| -------- | ---------- | -------- |
| U1       | PROVEN     | loading-red (entity missing) recorded; `e815925`/`6106c53` |
| U2       | PROVEN     | loading-red (store missing); `896d691` |
| U3       | PROVEN     | `UnimplementedError` red; `1732e87` |
| U4       | PROVEN     | `UnimplementedError` red; `248c439` |
| U5       | TEST_AFTER | first-run pass; mutant killed (prompt section dropped) |
| U6       | PROVEN     | `UnimplementedError` red; `4815867` |
| U7       | PROVEN*    | red was a fixture bug (Decision lines mid-line), repaired, then green — behavior itself was already implemented; *effectively test-after with fixture-repair red |
| U8       | TEST_AFTER | first-run pass; mutant killed (memory not stored — after the first mutant application silently failed and was redone with an assertion) |
| U9       | TEST_AFTER | first-run pass; mutant killed (preserved slice inflated) |
| U10      | TEST_AFTER | red was a test arithmetic bug, repaired, then green; mutant killed (messageCountThreshold branch removed) |
| U11      | TEST_AFTER | first-run pass; mutant killed (fallback memory not stored) |
| A1-A5    | (map)      | A1→U4/U6, A2→U8/U11, A3→U6/U7, A4→U2, A5→U10 — all through the public API |

## Findings

| # | Severity | Finding | Evidence |
| - | -------- | ------- | -------- |
| 1 | MED | The compressor core was built in three bundled greens (U3 gate, U4 path, U6 fallback) so nine dedicated tests never saw their own red; all were mutant-verified instead | cycle log cycles 5, 8-11 |
| 2 | LOW | One deliberate-mutant application silently failed (replace pattern missed) and initially reported a false "0 errors"; redone with an application assertion — the discipline now requires asserting the mutant applied | cycle log cycle 8 |
| 3 | LOW | Three test fixtures needed repair during cycles (AgentMessage cast, line-based Decision extraction, chars→tokens arithmetic) — each was a test bug, honestly recorded | cycles 1, 7, 10 |
| 4 | LOW | The auditor is the same session that wrote the tests | this file |

No existing tests were weakened; the feature only adds files.

## Mutation results

| Mutant | Behavior | Survived | Judgment |
| ------ | -------- | -------- | -------- |
| prompt drops `<current_plan>` | U5 | No | caught |
| memory created but not stored (llm path) | U8 | No | caught (after re-application with assertion) |
| keepRecentMessages tripled | U9 | No | caught (budget exceeded) |
| messageCountThreshold branch removed | U10 | No | caught |
| fallback memory not stored | U11 | No | caught |
| fallback returns unvalidated raw summary (in-cycle check) | U6 | No | caught via five-section assertions |

## Traceability

| Criterion | Tests | End to end |
| --------- | ----- | ---------- |
| AC-1 | U4, U5, U6 | Yes — through `compress()` |
| AC-2 | U8, U11 | Yes |
| AC-3 | U6, U7 | Yes |
| AC-4 | U1, U2 | Yes — through the store retrieval surface |
| AC-5 | U10 | Yes |

Untested criteria: none. Tests tracing to nothing: none. SC-002 (decisions and
file state preserved) is pinned structurally: the prompt contract (U5) names
the sections and the snapshot validator (U6) enforces them; content quality
beyond the section contract has no criterion (documented out of scope).

## What was not audited

- Mutation strength is a 6-mutant sample (no Dart mutation tool installed).
- Coverage unmeasured (formatter package absent).
- Snapshot CONTENT quality (is the summary actually good?) — no criterion; the
  fake LLM returns a fixed snapshot.
- Engine-loop trigger wiring and tool-registry integration — out of scope.
- The audit was performed by the same session that wrote the tests.

## Remediation tasks

Appended to `tasks.md` as Phase 5. The blocking finding is the TEST_AFTER
discipline gap (9 behaviors), not a test smell — consistent with specs 002/004/007/008
(TEST_AFTER-only FAIL, 0 HIGH smells, no code-level remediation). The MED finding
is process-level (carried into future specs); the code-level items are LOW.
