---
feature: 070-sub-agent-dispatch-runtime
verdict: PASS
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md
verified_at: HEAD of feat/spec-070-sub-agent-dispatch # baseline 8a5bd83
behaviors: 13 # A1-A8, U1-U5
proven: 13
likely: 0
test_after: 0
no_test: 0
high_smells: 0
criteria_total: 8 # FR-001..FR-008
criteria_covered: 8
mutation_score: 100 # deliberate-mutant sampling: 5 of 5 killed (M1-M5)
mutants_survived: 0
suite: 937 passed, 0 failed, 2 skipped # baseline 925/2 at 8a5bd83 + 12 new; skips are pre-existing KIMI_API_KEY integration tests
---

# Verification: Sub-agent dispatch runtime (spec 070)

**Branch**: `feat/spec-070-sub-agent-dispatch` (stacked on `feat/spec-069-mission-runner`)
**Verified at**: branch HEAD | **Baseline**: 925 passed / 2 skipped at `8a5bd83`, analyze clean

## Verdict: PASS

All 8 spec FRs implemented and traced; genuine RED → GREEN on the first
implementation pass; 5/5 deliberate mutants killed; both gates green with
real counts.

## Cycle log

### RED (genuine)

Whole test file (12 tests: 3 `AllowlistToolDispatcher` standalone + 9
service tests) written FIRST against the missing
`lib/src/engine/sub_agent_dispatch.dart`:

```
test/engine/sub_agent_dispatch_test.dart:21:8: Error: Error when reading
  'lib/src/engine/sub_agent_dispatch.dart': No such file or directory
test/engine/sub_agent_dispatch_test.dart:152:21: Error: Method not found: 'AllowlistToolDispatcher'.
test/engine/sub_agent_dispatch_test.dart:215:23: Error: Method not found: 'SubAgentDispatchService'.
00:00 +0 -1: Some tests failed.  (loading failure — library absent)
```

### GREEN

Implemented `sub_agent_dispatch.dart` (AllowlistToolDispatcher,
SubAgentDispatchStatus, SubAgentDispatchResult, SubAgentDispatchService)
→ `+12: All tests passed!` on the first full run. No test-side corrections
needed this cycle — the spec-069 planner semantics (consulted every turn)
were already internalized when authoring the fixtures.

### Mutations (deliberate, one at a time, cp-restored)

| id  | mutant | result | evidence |
| --- | ------ | ------ | -------- |
| M1  | allowlist check inverted | KILLED | `+8 -4` — U2/A2: forbidden tool now delegates, allowed refused |
| M2  | `totalRuns` not incremented | KILLED | `+9 -3` — A3/A4/bookkeeping asserts |
| M3  | system prompt dropped from child context | KILLED | `+11 -1` — A1 isolation witness (exact `[system, user]` capture) |
| M4  | risk-tier gate removed | KILLED | `+11 -1` — A5: refused dispatch now runs the LLM |
| M5  | `lastRunOutcome` hardcoded `'done'` | KILLED | `+9 -3` — A3/A4 status-name asserts |

Each mutant restored via `cp /tmp/sad_backup.dart`; file re-run to
`+12: All tests passed!` before the next mutant. **5/5 killed — no
survivors.**

### Gates (actually run, at branch HEAD after final restore)

- `dart pub get` — clean
- `dart analyze --fatal-infos` — `No issues found!` (exit 0)
- `dart test` — **937 passed / 0 failed / 2 skipped** (baseline 925/2 at
  `8a5bd83` + 12 new; skips are the pre-existing `KIMI_API_KEY`
  integration tests)

## FR traceability

| FR | status | evidence |
| -- | ------ | -------- |
| FR-001 isolated child context + result-only return | DONE | A1 (`CapturingLlmClient` sees exactly `[system, user]`; result summary only — no transcript field exists on the type) |
| FR-002 allowlist enforcement | DONE | A2 + U1/U2/U3 (boundary refusal, inner untouched, per-call batch) |
| FR-003 budgets | DONE | A3 (maxTurns 1 → `budgetExhausted`), U4 (wallClockTimeout via injected clock), U5 (fallback 10) |
| FR-004 instance bookkeeping | DONE | A4 (totalRuns 2→3, outcome name, input untouched) |
| FR-005 risk-tier gate | DONE | A5 (refused: 0 LLM calls, instance unchanged), A6 (grant → runs) |
| FR-006 event forwarding | DONE | A7 (MissionStarted/Completed carry `instance.id`) |
| FR-007 result value object + context snapshot | DONE | A8 (==/hashCode/toString; context fields incl. budgetTurns 4 vs fallback 10) |
| FR-008 gates | DONE | counts above |

## Notes / honest limitations

- `providerFailed` mapping is exercised only through the mapping switch
  (no dedicated service-level provider-failure test — the child-failure
  path is spec 069's A8; the mapping is 3 lines covered by M5's territory).
  Flagged for the record rather than padded with a duplicate test.
- One shared `LlmClientProvider` for all sub-agents (per-spec client
  resolution is future work — noted in spec out-of-scope).
- The `dispatch()` built-in tool and `spec.subAgents` recursion allowlist
  remain unwired (needs ChatCompletion tool-call fields — spec 058 declared
  the VO only).
