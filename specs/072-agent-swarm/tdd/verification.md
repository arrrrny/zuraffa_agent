# Verification: Agent swarm

---
feature: 072-agent-swarm
loop: outside-in
profile: .specify/memory/tdd-profile.md # referenced by sibling 023; file absent at HEAD — 023 artifact as de-facto rubric + constitution.md Principles II/V/X
executed_at: feat/spec-072-agent-swarm (stacked on feat/spec-070-sub-agent-dispatch @ 52ee56a)
gates:
  analyze: "dart analyze --fatal-infos → No issues found! (exit 0)"
  tests: "dart test → 947 passed / 0 failed / 2 skipped (baseline 937/2 at 52ee56a, +10 new)"
---

## Cycle integrity

This spec's cycle spanned a session cut-off; the honest reconstruction is
recorded here as Finding #1. File timestamps prove the original order:
`test/engine/agent_swarm_test.dart` written 17:12:38Z, impl
`agent_swarm.dart` written 17:46:53Z (test-first). The RED run's output was
lost with the session, so RED was REPRODUCED before writing this report:
impl moved aside → `dart test test/engine/agent_swarm_test.dart` failed
with the missing-library compile failure (`Error when reading
'lib/src/engine/agent_swarm.dart': No such file or directory`, then
`SwarmTask`/`AgentSwarm`/`SwarmStatus`/`SwarmStrategy` undefined, 8+
errors, exit 1) → impl restored → same file +10 green. The RED evidence
below is from that reproduction, not fabricated.

- **RED** (reproduced): missing-library compile failure, exit 1 — all 10
  tests unsatisfiable without `agent_swarm.dart`.
- **GREEN**: +10 on the swarm file (A1–A9 + U1 in one file; U2/U3 are
  asserted inside A1/A9 via the fake's captures); full suite 947/2.

## Acceptance criteria → tests (all FRs traced)

| FR | Test (test/engine/agent_swarm_test.dart) | Result |
| --- | --- | --- |
| FR-001 value objects + validation | `value objects carry house semantics`; `validation rejects empty, duplicate-id, and bad-quorum runs` | PASS |
| FR-002 concurrent fan-out | `members dispatch concurrently (overlap provable)` — probe `maxActive == 3` | PASS |
| FR-003 allCompleted barrier | `allCompleted returns a barrier over task-ordered results`; `…partialFailure when a member fails` | PASS |
| FR-004 firstCompleted | `firstCompleted wins on completion order, not submission order`; `…degrades to partialFailure` | PASS |
| FR-005 quorum | `quorum reached on the k-th success`; `quorum unmet fails with the true success count` | PASS |
| FR-006 pass-through wiring | `single-task swarm runs a real child mission end-to-end` — REAL SubAgentDispatchService, `MissionStarted.missionId == 't1'` reaches onEvent | PASS |
| FR-007 empty swarm | inside `validation rejects…` (`run(tasks: [])` → ArgumentError) | PASS |
| FR-008 gates | analyze clean; 947/2 vs baseline 937/2 | PASS |

## Mutation results (deliberate, one at a time, cp-restored)

| id | mutant | result | evidence (test file run) |
| -- | ------ | ------ | ------------------------ |
| M1 | fan-out made sequential (await each member before starting the next) | **KILLED** | +8 −2: probe `Expected: <3> Actual: <1>`; firstCompleted winner `Expected 'b' Actual 'a'` |
| M2 | allCompleted status hardcoded `completed` (failures ignored) | **KILLED** | +9 −1: `Expected: SwarmStatus:<partialFailure> Actual: SwarmStatus:<completed>` |
| M3 | firstCompleted picks submission order (await-all, first task-order success) | **KILLED** | +9 −1: winner `Expected: 'b' Actual: 'a'` |
| M4 | quorum trigger counts ALL completions, not just successes | **KILLED** | +8 −2: `Expected: quorumFailed Actual: quorumReached` (A7) AND `Expected: partialFailure Actual: firstCompleted` (A5 — failures now falsely "win") |
| M5 | `winner` never assigned on firstCompleted | **KILLED** | +9 −1: `Expected: not null Actual: <null>` |

**5/5 killed.** Every mutant was applied via targeted edit to a cp-backed-up
`agent_swarm.dart`, run, then restored with `cp` (the 066 process incident's
lesson — never `git checkout` uncommitted mutant files), and the restored
file re-verified green (+10) before the next mutant.

## Gates (actual runs at branch HEAD)

- `dart analyze --fatal-infos` → **No issues found!** (exit 0)
- `dart test` → **947 passed / 0 failed / 2 skipped** (2 pre-existing KIMI_API_KEY skips, unrelated)

## Findings

1. **Session cut-off mid-cycle (process, self-reported).** The original RED
   run happened at 17:12Z (test file timestamp) but its output was lost when
   the session was cut before verification. RED was reproduced honestly
   before this report was written (impl moved aside, compile failure
   captured, impl restored). All mutation runs in this report ran in the
   CURRENT session start-to-finish with outputs captured verbatim.
2. **M1 killed A4 as a side effect** (sequential fan-out also flips
   firstCompleted to submission order) — two kills from one mutant, both
   attributable to the same defect class (lost concurrency).
3. **Non-cancellation semantics** (FR-004) are documented, not asserted: no
   test asserts that losing members are cancelled, because they are NOT —
   Dart futures are non-cancellable; early-return strategies cancel only
   the result STREAM subscription and let member futures complete detached.
   A9 uses the REAL dispatch service (not the fake) to prove the whole
   070 → swarm stack runs end-to-end.

## Verdict

**PASS** — FR-001..FR-008 all traced to passing tests; 5/5 deliberate
mutants killed; both gates clean at branch HEAD; cycle integrity preserved
through the session cut-off via honest RED reproduction (Finding #1).
