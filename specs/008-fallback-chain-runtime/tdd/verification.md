---
feature: 008-fallback-chain-runtime
verdict: FAIL
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # short SHA re-audited; regraded FAIL (prior PASS_WITH_GAPS violated rubric verdict table: any TEST_AFTER -> FAIL)
behaviors: 25
proven: 24
likely: 0
test_after: 1
no_test: 0
high_smells: 0
criteria_total: 7
criteria_covered: 7
mutation_score: 100 # deliberate-mutant sampling: 6/6 killed during cycles + audit (1 survivor found and eliminated by rewriting U15)
mutants_survived: 0
suite: 442 passed, 6 failed (all 6 pre-date the feature: unrelated loading failures), 24s
---

# TDD Verification: Fallback Chain Runtime

**Verdict: FAIL.** Every acceptance criterion is covered end to end through
`FallbackChainClient`'s public API, 24 of 25 behaviors have genuine recorded
reds (including the two entity behaviors whose tests predate the implementation
in git history), and all 6 deliberate mutants were killed — including one
surviving mutant that forced a test rewrite. The single TEST_AFTER behavior
(U15: half-open probe routing) passed on first run with no red recorded, and the
rubric's verdict table fails closed on *any* TEST_AFTER or NO_TEST behavior, so
the verdict is FAIL despite the otherwise strong net. (The prior draft graded
this PASS_WITH_GAPS; that contradicts the rubric's FAIL condition and is
corrected here for consistency with specs 002/004/007.)

## Test-first evidence

| Behavior | Class      | Evidence |
| -------- | ---------- | -------- |
| U1-U4    | PROVEN     | `client_health_test.dart` committed in master history BEFORE the branch; loading-red recorded; impl `0a68279` |
| U5       | PROVEN     | `fallback_chain_test.dart` predates branch; compile-red recorded; impl `0d26a30`; spec-053 characterization tests stayed green |
| U6       | PROVEN     | cycle 3 red `UnimplementedError`; `a849d3f` |
| U7       | PROVEN     | cycle 4 red `Expected: halfOpen Actual: open`; `9fe89a9` |
| U8       | PROVEN     | cycle 5 red `Expected: <1> Actual: <4>`; `60efe42` |
| U9       | PROVEN     | cycle 6 reds: missing member + `Expected: false Actual: true` on isHealthy; `115f5bc` |
| U10      | PROVEN     | cycle 7 red `UnimplementedError`; `379d3b5` |
| U11      | PROVEN     | cycle 8 red (5xx rethrown, B never served); `3a85062` |
| U12      | PROVEN     | cycle 9 red (context-overflow 400 rethrown); `747b823` |
| U13      | PROVEN     | cycle 10 red `THREW: LlmHttpException ... 503` (not the typed error); `6b1efc4` |
| U14      | PROVEN     | cycle 11 red `Expected: 'from-b-again' Actual: 'a-recovered-early'`; `85a6a52` |
| U15      | TEST_AFTER | passed first run; deliberate mutant SURVIVED the first test version; test rewritten to pin probe-closes-breaker; rewritten test kills the mutant. Strong, but no red exists |
| U16      | PROVEN     | cycle 13 red `UnimplementedError`; `d9928c1` |
| U17      | PROVEN     | cycle 14 red `Expected: throws <LlmNetworkException> Actual: <Future>`; `6c49f5e` |
| U18      | PROVEN     | cycle 15 red `UnimplementedError`; `40b749a` |
| A1-A7    | PROVEN     | each maps to a PROVEN behavior's test through the public API (A1→U10, A2→U15, A3→U16, A4→U6, A5→U7, A6→U8, A7→U18) |

## Findings

| # | Severity | Finding | Evidence |
| - | -------- | ------- | -------- |
| 1 | MED | Two red/green commits landed with the test still red because `dart test | tail -1` masked non-zero exit codes in the command pipeline (U9 `657ff3d`, U18 `7793f36`); both were caught by the next full-suite run and fixed immediately | cycle log cycles 6 and 15 |
| 2 | LOW | The auditor is the same session that wrote the tests — the audit is not independent | this file |
| 3 | LOW | U15's first test version was worthless against the recordSuccess mutant (closed vs stuck-half-open indistinguishable) — caught by the audit-phase mutant discipline and rewritten | cycle log cycle 12 |

No existing tests were weakened: the merged `FallbackChain` kept the green
spec-053 provider tests green (characterization), and the 413 passing baseline
tests from spec 007 all still pass.

## Mutation results

Deliberate mutants (no mutation tool installed — profile `mutation: null`),
each restored and suites re-run green:

| Mutant | Behavior | Survived | Judgment |
| ------ | -------- | -------- | -------- |
| chain: recordSuccess removed (v1 test) | U15 | **Yes** | first test version worthless — rewritten, then killed |
| chain: recordSuccess removed (v2 test) | U15 | No | rewritten test pins probe-closes-breaker |
| chain: breaker gate removed | U14 | No | caught (audit re-sample) |
| chain: skip/restart policy inverted | U17 | No | caught (audit re-sample) |
| breaker: snapshot hardcoded closed | U18 | No | caught (audit re-sample) |
| breaker: isHealthy projected true for half-open | U9 | No | caught (in-cycle) |

## Traceability

| Criterion | Tests | End to end |
| --------- | ----- | ---------- |
| AC-1 | U10 | Yes — through `FallbackChainClient.generate()` |
| AC-2 | U15, U7, U9 | Yes |
| AC-3 | U16, U17 | Yes — through `stream()` |
| AC-4 | U6 | Yes |
| AC-5 | U7 | Yes |
| AC-6 | U8 | Yes |
| AC-7 | U18 + entity tests | Yes — `healthSnapshot()` through the public API |

Untested criteria: none. Tests tracing to nothing: none. FR-003's error
classes are each individually pinned (connection U10, 5xx/429 U11, context
overflow U12); FR-004's two policies are individually pinned (U16 restart,
U17 skip).

## What was not audited

- Mutation strength is a 6-mutant sample, not an exhaustive run (no Dart
  mutation tool in the repo).
- Coverage was not measured (formatter package absent; adding deps mid-loop is
  forbidden by the profile).
- Concurrency: simultaneous calls while a breaker is half-open (single-probe
  exclusivity under parallelism) — no criterion, single-threaded engine loop.
- Persistence of breaker state across restarts — out of scope per spec.
- The audit was performed by the same session that wrote the tests.

## Remediation tasks

Appended to `tasks.md` as Phase 7. The blocking finding is the TEST_AFTER
discipline gap (U15), not a test smell — consistent with specs 002/004/007
(TEST_AFTER-only FAIL, 0 HIGH smells, no code-level remediation). The two
LOW/MED items are process notes already compensated by the next-suite discipline
and the full-suite gate. Phase 7 keeps one MED process task (T034: never pipe a
single-test run through `tail` so a red cannot be committed silently).
