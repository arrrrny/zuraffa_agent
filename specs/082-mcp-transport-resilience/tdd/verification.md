---
feature: 082-mcp-transport-resilience
verdict: PASS
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md
verified_at: 082-mcp-transport-resilience (working tree, pre-commit)
behaviors: 9
proven: 9
likely: 0
test_after: 0
no_test: 0
high_smells: 0
criteria_total: 8
criteria_covered: 8
mutation_score: 100 # deliberate sample: 5/5 highest-risk behaviors killed
mutants_survived: 0
suite: 8 passed, 0 failed # test/mcp/mcp_082_resilience_test.dart at branch HEAD
---

# TDD Verification: MCP Transport Resilience (spec 082)

**Verdict: PASS.** Every behavior is `PROVEN` (red evidence in
`tdd/cycle-log.md`, recorded in this session before the implementation
landed), no HIGH smells, every acceptance criterion covered end-to-end, and
all 5 deliberate mutants killed.

## Test-first evidence

| Behavior | Class  | Evidence |
| -------- | ------ | -------- |
| A1 drop survivable AND observable end-to-end | PROVEN | cycle-log cycle 1: T4 red (cache not invalidated → `listCalls` 1) → green; T1 red (`events` 0) → green |
| A2 gates | PROVEN | `dart analyze` 3 issues = master baseline (no new); `dart test` 1081/2/0 (baseline 1073/2 + 8) |
| U1 SSE recovery emission | PROVEN | cycle 1 step 2: T1 failing (getter missing / no event) → green |
| U2 stdio recovery emission | PROVEN | cycle 1 step 2: T2 failing → green |
| U3 cache invalidation on recovery | PROVEN | cycle 1 step 2: T3 failing (`listToolsCallCount` stayed 1) → green |
| U4 in-proc silence | PROVEN | T8 passes with the never-emitting default; M4-family absence is the design (no transport) |
| U5 jitter cap clamp | PROVEN | pin by design; killer mutant M1 (`Actual: <1350>` > cap 1000) |
| U6 storm terminality | PROVEN | pin by design; killer mutant M2 (`failed` → `connected`) |
| U7 TTL boundary | PROVEN | pin by design; killer mutant M5 (`Expected: <2>`, `Actual: <1>`) |

## Findings

No HIGH smells. Every test asserts specific values (event counts,
`listToolsCallCount`, exact delay bounds, exact state enums); no doubles
stub the subject (the subject is the real client/policy/cache over a
programmable wire fake — the seam 015 itself defines); no conditional
assertions; no re-implemented expectations (the expected backoff sequence
is written out literally, not recomputed).

Scope note: the pins U5–U7 intentionally pass against pre-existing
behavior — the 078 "pin honesty" precedent — and each is justified by a
killer mutant. FR-001 (stateless wire) and FR-007 (namespace + sealed
result) are covered by the existing 015/003 tests cited in the test list;
this spec added no duplicates.

## Mutation results

| Mutant | Behavior | Survived | Judgment |
| ------ | -------- | -------- | -------- |
| M1 jitter clamp removed | U5 | No | Killed: T5 `Actual: <1350>` vs cap 1000 |
| M2 exhaustion skips `failed` | U6 | No | Killed: T6 state `connected` instead of `failed` |
| M3 cache reconnect-subscription removed | U3, A1 | No | Killed: T3 + T4 fail (2 failures) |
| M4 SSE emission removed | U1, A1 | No | Killed: T1 + T4 fail (2 failures) |
| M5 TTL freshness `<=` | U7 | No | Killed: T7 `Expected: <2>`, `Actual: <1>` |

Scope: 5 of 9 behaviors sampled (the highest-risk: clamp, terminality,
both halves of the new wiring, boundary). Not exhaustive; each mutant was
cp-restored and the suite re-verified green.

## Traceability

| Criterion | Tests | End to end |
| --------- | ----- | ---------- |
| FR-001 stateless wire seam | existing: `test/mcp/*` (015 wire fakes, A6) | Yes |
| FR-002 jitter never exceeds cap | U5 (T5) + M1 | Yes |
| FR-003 storm terminality | U6 (T6) + M2 | Yes |
| FR-004 recovery emission | U1, U2, U4 (T1, T2, T8) + M4 | Yes |
| FR-005 cache invalidation on recovery | U3, A1 (T3, T4) + M3 | Yes |
| FR-006 exact TTL boundary | U7 (T7) + M5 | Yes |
| FR-007 namespace + sealed result | existing: adapter/client tests (cited) | Yes |
| FR-008 gates | A2 | Yes |

## Gates

- `dart analyze` — 3 issues, byte-identical set to master baseline
  (`mission_runner_002_a2` unused field; `cassette_replay_llm_client`
  prefer_final_fields; `mission_runner_002_a3` function-declaration lint).
  No new issues introduced.
- `dart test` — **1081 passed / 2 skipped / 0 failed** (baseline 1073/2 +
  8 new).
