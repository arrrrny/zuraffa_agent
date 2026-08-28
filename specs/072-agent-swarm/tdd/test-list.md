# Test List: Agent swarm

---
feature: 072-agent-swarm
loop: outside-in
profile: .specify/memory/tdd-profile.md # referenced by sibling 023; file absent at HEAD — 023 artifact as de-facto rubric + constitution.md Principles II/V/X
spec_criteria: 8 # FR-001..FR-008 in spec.md
planned_at: 52ee56a # feat/spec-070-sub-agent-dispatch HEAD (stack base)
updated_at: HEAD
suite_baseline: green # 937 passed / 2 skipped at 52ee56a
---

## Outer loop: acceptance behaviors

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| A1  | Concurrent fan-out: 3 scripted members with real delays — the in-flight probe observes `maxActive == 3` (all dispatches started before any completed) | FR-002 | example | PASSING | `test/engine/agent_swarm_test.dart::spec 072 — AgentSwarm::members dispatch concurrently (overlap provable)` |
| A2  | allCompleted happy: every member succeeds → `completed`, `completedCount == 2`, results in TASK order, winner null | FR-003 | example | PASSING | `…::allCompleted returns a barrier over task-ordered results` |
| A3  | allCompleted partial: one member fails → `partialFailure`, `completedCount == 1` | FR-003 | example | PASSING | `…::allCompleted reports partialFailure when a member fails` |
| A4  | firstCompleted: the FASTEST member wins regardless of task order (A slow, B fast → winner B), `firstCompleted`, `results == [winner]`, `completedCount == 1` | FR-004 | example | PASSING | `…::firstCompleted wins on completion order, not submission order` |
| A5  | firstCompleted no-success: every member fails → `partialFailure`, winner null, all results, `completedCount == 0` | FR-004 | example | PASSING | `…::firstCompleted without any success degrades to partialFailure` |
| A6  | quorum reached: 2 successes of 3 (third slow failure) → `quorumReached`, `completedCount == 2`, results are the two successes in completion order | FR-005 | example | PASSING | `…::quorum reached on the k-th success` |
| A7  | quorum failed: 0 successes of 3 with k=2 → `quorumFailed`, all results, `completedCount == 0` | FR-005 | example | PASSING | `…::quorum unmet fails with the true success count` |
| A8  | Validation: empty tasks, duplicate ids, quorum missing / < 1 / > tasks.length each throw `ArgumentError` | FR-001, FR-005, FR-007 | example | PASSING | `…::validation rejects empty, duplicate-id, and bad-quorum runs` |
| A9  | Real-service integration: single-task swarm over the REAL SubAgentDispatchService (fake LLM) → child mission actually runs, summary surfaces, `MissionStarted.missionId == task.id` reaches onEvent | FR-006 | example | PASSING | `…::single-task swarm runs a real child mission end-to-end` |
| A10 | Gates: `dart analyze --fatal-infos` exit 0; full `dart test` green (baseline 937/2 + new) | FR-008 | gate | PASSING | gates at branch HEAD: analyze clean; 947/2 |

## Inner loop: unit behaviors

### `lib/src/engine/agent_swarm.dart` (new)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U1  | `SwarmTask` / `SwarmTaskResult` / `SwarmResult` value semantics (==, hashCode, toString) | FR-001 | example | PASSING | `…::value objects carry house semantics` |
| U2  | Member instance synthesis: `SubAgentInstance(id: task.id, subAgentSpecId: spec.name, parentSessionId: 'swarm', totalRuns: 0)` reaches the dispatch service | FR-002 | example | PASSING | A1/A9 fake assertions |
| U3  | `clock` / `adminGranted` / `onEvent` forwarded to every member dispatch | FR-006 | example | PASSING | A9 + A1 fake capture |

## Invariants and edge cases

- Overlap invariant: eager fan-out — maxActive == tasks.length for any nonzero delays (A1, deterministic: async bodies run synchronously to first await).
- Attribution invariant: member events carry task.id as missionId (A9).
- Non-cancellation honesty: early strategy return leaves siblings detached by design (FR-004 doc; no test asserts cancellation).
- No new EngineEvent subtypes; no swarm events invented.

## Mutation plan (deliberate, one at a time, cp-restored)

| id  | mutant | killed by |
| --- | ------ | --------- |
| M1  | fan-out made sequential (await each task before starting the next) | A1 (maxActive 1 vs 3) |
| M2  | allCompleted status hardcoded `completed` (failures ignored) | A3 |
| M3  | firstCompleted returns `tasks.first` result (submission order) | A4 (winner would be the slow A) |
| M4  | quorum trigger counts ALL completions, not just successes | A7 (two failures would falsely reach k=2) |
| M5  | `winner` never assigned on firstCompleted | A4 |
