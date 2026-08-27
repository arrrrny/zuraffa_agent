---
feature: 29-tool_call_signature-datasource-pair
verdict: PASS
verified_at: 4547b6a
behaviors_total: 16
behaviors_done: 16
test_first: 15 PROVEN, 1 NOT_APPLICABLE (U7 baseline)
mutation: 4/4 killed (one mutant required an honest re-application after a corrupted first attempt)
criteria_covered: 7/7 acceptance criteria, 7/7 FRs
suite: 562 passed, 0 failed
analyze: 5 pre-existing issues, 0 new
---

# TDD Verification: ToolCallSignature datasource + mock pair

## Verdict

**PASS** — content addressing (identity, key derivation, equality) and the
capture/lookup persistence contract are traced to passing tests through the
datasource public API, all behavioral changes landed test-first with recorded
red evidence, and every deliberate mutant was killed.

## Test-first evidence

| class          | behaviors | evidence |
| -------------- | --------- | -------- |
| PROVEN         | A3/A4+U1..U6 (cycle 1), A1/A2+U8/U9 (cycle 2), A5..A7 (cycle 3) | cycle-log red blocks + git ordering (test-only commits before implementation commits; cycle 2/3 share one test commit but two staged implementation commits with the intermediate red recorded) |
| NOT_APPLICABLE | U7 (compile-parity characterization) | green against pre-existing surface |

Red-phase failure modes: compile errors (`No named parameter with the name
'toolName'`, `The method 'capture'/'lookup' isn't defined`) for missing surface;
`UnimplementedError: Implement ToolCallSignatureMockDatasource.count` for the
deliberately deferred cycle-3 surface.

Changes to pre-existing tests: 3 `UnimplementedError` stub assertions superseded
(documented drift remediation); compile-parity check kept.

## Mutation results (deliberate hand-mutants)

| mutant | change | run | result |
| ------ | ------ | --- | ------ |
| M1 key drops version | key format loses `$version` | U3 | KILLED — `Expected: 'webview.browse@2:abc123', Actual: 'webview.browse@:abc123'` |
| M2 legacy id in equality | `==` includes `id` | U6 | KILLED — content-equal signatures with different ids became unequal |
| M3 insertion-index keying | `capture` keys by `'entry-N'` instead of content | A5 + A1 | KILLED — A5 `Expected: <1> Actual: <2>` (idempotency broken) and A1 `Expected: not null, Actual: <null>` (round-trip broken) |
| M4 phantom miss | `lookup` fabricates an entry on miss | A2/U8 | KILLED — `Expected: null, Actual: ToolCallSignature(...)` |

Deviation honestly recorded: M3's first application was corrupted by a shell
escaping slip — the mutant collapsed to a single literal key, under which A5
passed. Recognized as a false mutant (not a survivor), re-applied correctly
against the real code, and killed by two behaviors. Every mutant was restored
exactly (`git diff --stat lib/` = 0 lines) with the affected files re-run green.

## Acceptance-criteria coverage

| criterion | behaviors | status |
| --------- | --------- | ------ |
| AC US1-1 capture→lookup round-trip | A1 (+M3 killed) | PROVED |
| AC US1-2 miss reports absence, no throw | A2/U8 (+M4 killed) | PROVED |
| AC US2-1 equal content ⇒ equal identity | A3/U1 | PROVED |
| AC US2-2 differing component ⇒ different identity | A4/U2 (+M1 killed) | PROVED |
| AC US2-3 idempotent capture | A5 (+M3 killed) | PROVED |
| AC US3-1 count reflects distinct captures | A6 | PROVED |
| AC US3-2 reset clears store | A7 | PROVED |

FR-001..FR-007 all traced (test-list traces column); SC-001..SC-006 proved
(SC-006 via final gates below).

## Final gates

- `dart test` -> **562 passed, 0 failed** (post-27 baseline 551; net +11)
- `dart analyze` -> 5 issues, all pre-existing and unrelated. Zero new issues.

## Findings

- **LOW** — M3's corrupted first application initially read as a survivor. The
  check that exposed it (inspecting the applied diff rather than trusting the
  mutation command) is recorded here so the procedure keeps it: a mutant that
  passes must first be proven to be the mutant you intended.
- **INFO** — cycles 2 and 3 share one test-first commit with two staged
  implementation commits; the intermediate run (cycle-2 acceptance green,
  cycle-3 behaviors red on `UnimplementedError`) is recorded in the cycle log.
  Ordering evidence in git is therefore coarser than one-commit-per-cycle but
  still unambiguous.

No HIGH findings. No criteria without tests. No tests tracing to nothing.
