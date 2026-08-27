---
feature: 007-llm-provider-clients
verdict: FAIL
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 9117fa2 # short SHA audited
behaviors: 30
proven: 13
likely: 0
test_after: 13
no_test: 0
high_smells: 0
criteria_total: 8
criteria_covered: 8
mutation_score: 100 # deliberate-mutant sampling only (no mutation tool installed): 17/17 killed across cycles + audit
mutants_survived: 0
suite: 413 passed, 8 failed (all 8 pre-date the feature: loading failures of unrelated unimplemented specs), 23s
---

# TDD Verification: LLM Provider Clients

**Verdict: FAIL.** Thirteen of thirty behaviors are TEST_AFTER by the rubric's
letter — their implementations landed in earlier commits than their dedicated
tests (bundled greens), and each was compensated by a first-run pass plus a
killed deliberate mutant, but no genuine red exists for them. Every acceptance
criterion is covered through the clients' public API, all 17 deliberate
mutants were killed, and no HIGH test smells were found — the failure is a
discipline finding, not a coverage or strength finding.

## Test-first evidence

| Behavior | Class      | Evidence                                                                                     |
| -------- | ---------- | -------------------------------------------------------------------------------------------- |
| U1       | PROVEN     | cycle 1 red recorded (`Expected: <Instance of 'LlmUsage'>`); test+source in `2f98853`        |
| U2       | PROVEN     | cycle 2 red recorded (`contains '503'`); `a999071`                                            |
| U3       | PROVEN     | cycle 3 red recorded (`UnimplementedError`); `566d9a3`                                        |
| U4       | PROVEN     | cycle 4 red recorded (`UnimplementedError`); `a993347`                                        |
| U5       | TEST_AFTER | passed first run (loop landed in U4's green); mutant killed (500-not-retryable)               |
| U6       | TEST_AFTER | passed first run; mutant killed (exhaustion boundary off-by-one)                              |
| U7       | TEST_AFTER | passed first run; mutant killed (all-statuses-retryable)                                      |
| U8       | PROVEN     | cycle 8 red recorded (`Expected: [100, 200, 250, 250] Actual: [100, 200, 400, 800]`); `cf621e5` |
| U9       | PROVEN     | cycle 9 red recorded (`Expected: [7000] Actual: [100]`); `db9412f`+`fba4476`                 |
| U10      | PROVEN     | cycle 10 red recorded (`UnimplementedError`); `a990410`                                       |
| U11      | PROVEN     | cycle 11 red recorded; two in-cycle fix commits recorded honestly; `e9658aa`                  |
| U12      | PROVEN     | cycle 12 red recorded (`UnimplementedError`); `bab7144`                                       |
| U13      | TEST_AFTER | first red was a fixture bug (invalid JSON escaping), repaired; behavior then passed; mutant killed (index keying dropped) |
| U14      | TEST_AFTER | passed first run; mutant killed (generate swallows errors)                                    |
| U15      | PROVEN     | cycle 15 red recorded (`UnimplementedError`); `50537c4`/`8476211`                             |
| U16      | TEST_AFTER | passed first run; mutant killed (thinking_delta dropped)                                      |
| U17      | TEST_AFTER | fixture repair then pass; mutant killed (partial_json accumulation dropped)                   |
| U18      | TEST_AFTER | passed first run; mutant killed (provider label)                                              |
| U19      | PROVEN     | cycle 19 red recorded (`UnimplementedError`); `e6d6bf0`                                       |
| U20      | TEST_AFTER | passed first run; mutant killed (functionCall parts ignored)                                  |
| U21      | TEST_AFTER | passed first run; mutant killed (malformed reason normalized away)                            |
| U22      | TEST_AFTER | passed first run; mutant killed (provider label)                                              |
| A1       | TEST_AFTER | openai contract slice passed first run; mutant killed (content deltas dropped)                |
| A4       | PROVEN     | genuine red: cached tokens `Expected: <8> Actual: <0>` — a real gap the suite caught; `9117fa2` |
| A6       | TEST_AFTER | gemini contract slice passed first run; mutant killed (usageMetadata ignored)                 |
| A8       | PROVEN     | the shared suite failed for the right reason (anthropic cached tokens) before its fix         |

## Findings

Ordered by severity, each with evidence and the fix.

| #  | Severity | Finding                                                                                          | Evidence                                        |
| -- | -------- | ------------------------------------------------------------------------------------------------ | ----------------------------------------------- |
| 1  | HIGH     | 13 behaviors have no genuine red: implementations for U5-U7/U13-U18/U20-U22 and A1/A6 landed in earlier commits than their tests; pass-first runs were compensated by deliberate mutants but the rubric classifies them TEST_AFTER | cycle-log entries 5-7, 13-14, 16-18, 20-22, 23-26; git log test/source ordering |
| 2  | MED      | Two fixture-authoring bugs made tests red for the WRONG reason before the behavior red (invalid JSON escaping in openai/anthropic fixtures) — wasted a debugging cycle each; a JSON-literal fixture helper would prevent recurrence | `openai_compatible_client_test.dart` cycle 13; `anthropic_client_test.dart` cycle 17 |
| 3  | LOW      | `LlmToolCall.toString()` omits `arguments`, which masked the actual diff in two equality failures and cost debugging time | `lib/src/llm/llm_client.dart:143`              |
| 4  | LOW      | The auditor is the same session that wrote the tests — the audit is not independent (rubric Hard Rule 2 requires stating this) | this file                                       |

No existing tests were weakened, skipped, or filtered: the feature's diff adds
new files only, plus the pubspec stray-override removal (no test impact) and
the CI purity-allowlist addition with justification.

## Mutation results

No mutation tool is installed for this stack (profile: `mutation: null`), so
test strength was measured by deliberate mutants, one at a time, each restored
and the suite re-run green afterwards. 17 mutants, 17 killed, 0 survivors:

| Mutant                                                                   | Behavior | Survived | Judgment                        |
| ------------------------------------------------------------------------ | -------- | -------- | ------------------------------- |
| retry: `status >= 500` -> `status > 500`                                  | U5       | No       | caught                          |
| retry: exhaustion `>=` -> `>`                                             | U6       | No       | caught                          |
| retry: `_isRetryableStatus` -> always true                               | U7       | No       | caught                          |
| retry: cap removed                                                        | U8       | No       | caught (audit re-sample)         |
| openai: fragment keying `index = 0`                                      | U13      | No       | caught                          |
| openai: generate catches LlmHttpException                                | U14      | No       | caught                          |
| openai: cached-token parse dropped                                        | U11      | No       | caught (audit re-sample)         |
| anthropic: thinking_delta dead label                                      | U16      | No       | caught                          |
| anthropic: partial_json accumulation dropped                              | U17      | No       | caught                          |
| anthropic: provider label wrong                                           | U18      | No       | caught                          |
| anthropic: tool_use buffer never emitted                                  | U17      | No       | caught (audit re-sample)         |
| gemini: functionCall parts ignored                                        | U20      | No       | caught                          |
| gemini: malformed reason normalized away                                  | U21      | No       | caught                          |
| gemini: provider label wrong                                              | U22      | No       | caught                          |
| contract: openai content deltas dropped                                   | A1       | No       | caught                          |
| contract: anthropic message_delta usage dropped                           | A4       | No       | caught                          |
| contract: gemini usageMetadata ignored                                    | A6       | No       | caught                          |

Sampling, not exhaustive: mutants targeted the highest-risk behaviors
(usage accounting, tool-call assembly, retry boundaries, error surfacing).

## Traceability

| Criterion | Tests | End to end (public API over recorded fixtures) |
| --------- | ----- | ----------------------------------------------- |
| AC-1      | A1, U12, U13 | Yes — contract suite openai stream             |
| AC-2      | A2, U13 | Yes                                              |
| AC-3      | A3, U14, U2, U18, U22 | Yes                                      |
| AC-4      | A4, U16, U15 | Yes — contract suite anthropic stream         |
| AC-5      | A5, U17 | Yes                                              |
| AC-6      | A6, U20, U19 | Yes — contract suite gemini stream            |
| AC-7      | A7, U21 | Yes                                              |
| AC-8      | A8 (12 contract tests, 3 providers × 4 scenarios) | Yes                          |

Untested criteria: none. Tests tracing to nothing: none. FR-003 (multimodal
input) is asserted inside U11/U15/U19 body-mapping assertions; FR-007
(attribution + no dart_agent_core dependency) is verified by T042 gates
(pubspec grep clean, 8/8 files carry headers) — a repo-level check, not a dart
test, and recorded as such.

## What was not audited

- Mutation coverage is a 17-mutant sample, not an exhaustive run — no Dart
  mutation tool exists in the repo (profile records `mutation: null`).
- Coverage was not measured: `dart test --coverage` emits VM traces but the
  formatting package (`package:coverage`) is not installed and adding deps
  mid-loop is forbidden by the profile.
- Performance (first-chunk latency, backoff wall-time) was not assessed: no
  criterion, no test.
- Live-network behavior of `IoLlmTransport` beyond the loopback HttpServer
  test (TLS, proxies, HTTP/2) was not assessed.
- The audit was performed by the same session that wrote the tests (finding #4).

## Remediation tasks

Appended to `tasks.md` as Phase 8. On a FAIL verdict the feature is not
TDD-done until the blocking findings are addressed; given finding #1 is
historical (the tests exist and are mutant-strong), the actionable remediation
is process-level for the next specs plus the two code-level LOW/MED items.
