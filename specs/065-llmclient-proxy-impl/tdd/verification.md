---
feature: 065-llmclient-proxy-impl
verdict: FAIL
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md
verified_at: 01618f3
behaviors: 18
proven: 0
likely: 0
test_after: 18
no_test: 0
high_smells: 0
criteria_total: 3
criteria_covered: 3
mutation_score: 100 # deliberate-mutant sample on highest-risk path: 2 of 2 killed (U4 proxy connect, U11 timeout forward)
mutants_survived: 0
suite: U4 +1 passed (llm_http_transport_test.dart); U11 +1 passed (llm_client_provider_test.dart); full-suite baseline 909/0 per cycle-log (full ~900-test suite not re-run in this audit)
---

# TDD Verification: Full LlmClient with Local Proxy Support — spec 065

**Verdict: FAIL (discipline).** The feature was implemented and merged via PR #71
**before** any of its tests existed (the `tdd/065` branch was only opened
afterwards to close two unit gaps). No `cycle-log.md` red is recorded for any of
the 18 behaviors — red was *inferred* for U4/U11 via deliberate mutants, not
*observed*, so per the rubric every behavior grades `TEST_AFTER` (fail-closed).
Crucially, this is **not** a vacuous test-after: the two highest-risk behaviors
on the proxy/auth path (U4 direct-connect, U11 timeout forward) were proven
sensitive by deliberate mutants that both failed the right way and were restored
clean. The 16 other behaviors are plain regression snapshots with no red.

## Test-first evidence

| Behavior | Class                        | Evidence                                                                                                                        |
| -------- | ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| A1       | TEST_AFTER (example)         | Live proxy completion; no red. Skips on proxy unreachable.                                                                       |
| A2       | TEST_AFTER (example)         | `current()` no longer throws; no red recorded.                                                                                   |
| A3       | TEST_AFTER (example)         | SSE reassembly via contract suite; no red recorded.                                                                             |
| U1       | TEST_AFTER (example)         | OpenAI-compatible body; no red.                                                                                                 |
| U2       | TEST_AFTER (example)         | `stream` flag honored; no red.                                                                                                  |
| U3       | TEST_AFTER (example)         | Proxy routes via `findProxy` (integration test); no red.                                                                        |
| U4       | TEST_AFTER (mutant-proven)   | `cycle-log.md` Cycles 1: guard flipped so `findProxy` is assigned for a null proxy → single test failed (`Expected: false / Actual: <true>`); reverted → green. |
| U5       | TEST_AFTER (example)         | Response parse (content/reasoning/finish/usage); no red.                                                                        |
| U6       | TEST_AFTER (example)         | `reasoning_details` reassembly; no red.                                                                                          |
| U7       | TEST_AFTER (example)         | Missing `choices` → typed error; no red.                                                                                         |
| U8       | TEST_AFTER (example)         | Empty `content` → typed error; no red.                                                                                           |
| U9       | TEST_AFTER (example)         | `current()` returns active client; no red.                                                                                      |
| U10      | TEST_AFTER (example)         | `count()` returns usable clients; no red.                                                                                       |
| U11      | TEST_AFTER (mutant-proven)   | `cycle-log.md` Cycle 2: `timeout: config.timeoutMs` replaced with `timeout: null` → single test failed (`No matching calls … timeout: null`); reverted → green. |
| U12      | TEST_AFTER (example)         | `LlmClient` value equality; no red.                                                                                              |
| U13      | TEST_AFTER (example)         | Value-object field shape; no red.                                                                                               |
| U14      | TEST_AFTER (example)         | `LlmHttpException` carries provider/status/body/message; no red.                                                                |
| U15-U18  | TEST_AFTER (contract)        | Contract suite (generate / non-2xx / 429 retry / stream); no red.                                                               |

The `cycle-log.md` is explicit that U4/U11 are *test-after* (Hard Rule 2) and
that red was produced by a deliberate mutant rather than observed against
pre-existing code. That inference is accepted as evidence of test *sensitivity*,
not test-*firstness*.

## Findings

| #   | Severity | Finding                                                                                                                                                                                                                       | Evidence                                                                  |
| --- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| 1   | MED      | **Secrets hygiene untested on the auth path.** `spec.md` Edge Cases require the request/diagnostic path to *never log the API key* (FR-003 authenticates with a bearer key sourced from config). No test asserts this; the test-list records it as an unplaced edge case ("no log sink to capture"). This is a real gap on a high-risk (auth/secrets) path. It is an untested requirement, not a misleading test, so it is MEDIUM and non-blocking. | `spec.md` Edge Cases ("must not log the API key"); `test-list.md` §Invariants |
| 2   | LOW      | U4/U11 are graded `TEST_AFTER` because their red was inferred via deliberate mutants, not observed. Both mutants prove the tests are sensitive, but they do not retroactively establish that the tests existed before the code. Honest classification only. | `cycle-log.md` Cycles 1–2                                                |
| 3   | LOW      | The auditor is the same session that authored the artifacts — the audit is not independent.                                                                                                     | this file                                                                |
| 4   | LOW      | `A1` (US1 live proxy completion) and the US3 streaming contract depend on real network / live fixtures; `A1` skips when the proxy is unreachable. Acceptable for an integration test, but the end-to-end assertion is gated on live infra and is non-deterministic in CI. | `test/integration/llm_client_proxy_test.dart`                            |

No `HIGH` smells. The two mutant-proven behaviors (U4, U11) are confirmed
non-vacuous; the rest assert specific field values, exact timeout forwarding, or
typed-error types and are non-vacuous by inspection. No weakened or skipped
existing tests were found.

## Mutation results

No mutation tool is installed for this stack; deliberate mutants on the two
highest-risk behaviors (proxy connection path and upstream timeout forwarding),
each restored via `cp` backup and the suite re-run green afterwards. 2 mutants,
both killed:

| Mutant | Behavior | Survived | Judgment |
| ------ | -------- | -------- | -------- |
| M1 — flip the proxy guard in `llm_http_transport.dart` to `proxyUrl == null \|\| proxyUrl.isNotEmpty` (with a non-null fallback host) so `findProxy` is installed even for a null proxy | U4 (FR-002) | No | caught — `dart test … -n "no findProxy"` → `Expected: false / Actual: <true> / findProxy must not be installed when proxyUrl is null`, exit 1; reverted to `proxyUrl != null && proxyUrl.isNotEmpty`, test green (`llm_http_transport.dart:127`). |
| M2 — replace `timeout: Duration(milliseconds: config.timeoutMs)` with `timeout: null` in `llm_client_provider.dart` | U11 (FR-003) | No | caught — `dart test … -n "forwards ProviderConfig.timeoutMs"` → `No matching calls. All calls: MockLlmHttpTransport.complete({… timeout: null})`, exit 1; reverted to `timeout: Duration(milliseconds: config.timeoutMs)`, test green (`llm_client_provider.dart:67`). |

Source of evidence: `tdd/cycle-log.md` Cycles 1–2 (exact failure output quoted
there). The current working tree was confirmed clean — both spec tests pass
(`+1` each) at `verified_at: 01618f3`, proving the mutants were restored exactly.
The mutants were **not** re-executed in this audit to avoid further tree
mutation while an unrelated concurrent process was editing engine-event files;
the recorded runs plus the present green state are treated as sufficient.

Sampling, not exhaustive: mutants targeted the two behaviors an acceptance
criterion and the auth/proxy path depend on. The other 16 behaviors were not
mutated (they are plain example/contract snapshots, several behind live-network
integration gates).

## Traceability

| Criterion (spec.md) | Tests | End to end (public API) |
| ------------------- | ----- | ----------------------- |
| US1 — real completion through the proxy | A1, U3 | Yes (integration, skips if unreachable) |
| US2 — config-driven client resolution | A2, U9, U10 | Yes |
| US3 — streaming where advertised | A3, U18 | Yes (contract) |
| FR-002 — proxy when set, direct connect when none (U4) | U3, U4 + mutant M1 | Yes |
| FR-003 — bearer auth from config; timeout forwarded (U11) | U11 + mutant M2 | Yes (U11 unit); auth header itself integration-gated |

`criteria_total: 3` (the three user stories, per `test-list.md spec_criteria`).
All three are covered by a DONE test. Untested requirements: **secrets hygiene**
(API key never logged) — an Edge-Case requirement with no test (finding #1).
Tests tracing to nothing: none.

## What was not audited

- The full ~900-test suite was not re-run end to end; only the two spec tests
  (U4, U11, each `+1` green) were executed, plus the 064 spec file in a sibling
  audit. Suite baseline per `cycle-log.md` is 909/0.
- The two deliberate mutants were not re-executed in this pass; their evidence is
  the recorded `cycle-log.md` runs, corroborated by the present green state.
- Coverage tooling is not installed (profile forbids mid-loop dep additions).
- The live-proxy integration test (A1/US1) was not exercised against real infra
  (it skips without a reachable proxy); its assertion quality was reviewed from
  source, not run live.

## Remediation tasks

None blocking. No `HIGH` finding was raised. The MEDIUM secrets-hygiene gap
(finding #1) is recommended as a future small cycle (capture the logger / stdout
and assert the api_key is absent) rather than a blocking remediation; it does not
block the current delivery. All other findings are LOW and informational.
