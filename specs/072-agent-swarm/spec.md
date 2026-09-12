**Template Version**: `zuraffa-1.0`

# Feature Specification: Agent swarm

**Branch**: `feat/spec-072-agent-swarm` (stacked on `feat/spec-070-sub-agent-dispatch`, PR #81) | **Date**: 2026-08-29

## Summary

Orchestrate multiple agents as one swarm: fan a set of `SwarmTask`s out to
CONCURRENT sub-agent dispatches (spec 070's `SubAgentDispatchService`) and
aggregate them under one of three strategies — `allCompleted` (barrier),
`firstCompleted` (first successful member wins), `quorum(k)` (k successes
suffice). The word "swarm" appears nowhere in the repo today; this spec
introduces the concept on top of the dispatch runtime the same stack just
delivered, closing the user's "agent swarm" ask with real concurrency
(provable overlap), typed per-member results, and honest non-cancellation
semantics.

Design stance: a swarm is **fan-out + aggregation, not supervision**. It
does not cancel losing members (Dart futures are not cancellable;
engine-level cancellation is future work — non-winning members run to
completion detached, documented as such), does not re-dispatch failures
(no retry policy), and invents no new `EngineEvent` subtypes (the union
grows only from its own spec). Member events flow to the caller's sink
keyed by task id.

## Files

- `lib/src/engine/agent_swarm.dart` — NEW: `SwarmStrategy`, `SwarmTask`,
  `SwarmTaskResult`, `SwarmStatus`, `SwarmResult` (house value semantics),
  `AgentSwarm`.
- `test/engine/agent_swarm_test.dart` — NEW: a
  `SubAgentDispatchService`-shaped fake with per-task latency/status scripts
  and an active-count concurrency probe, plus one REAL-service integration
  test.
- `specs/072-agent-swarm/{spec,plan,tasks}.md` + `tdd/{test-list,verification}.md`.

## FRs

- **FR-001**: The system MUST satisfy this requirement: Value objects (spec 066 house pattern): `SwarmTask`
  (`id`, `spec: SubAgentSpec`, `mission`), `SwarmTaskResult` (`taskId`,
  `specName`, `status: SubAgentDispatchStatus`, `summary`), `SwarmResult`
  (`strategy`, `status`, `results`, `winner`, `completedCount`), each with
  `==`/`hashCode`/`toString`. Duplicate task ids are rejected with
  `ArgumentError` at `run()` (member instances key on task id).
  traces: AgentSwarm.fr1
- **FR-002**: The system MUST satisfy this requirement: Concurrent fan-out: every task's dispatch starts EAGERLY
  (all futures created before any is awaited — overlap is provable: a
  probe observing in-flight dispatches sees `maxActive == tasks.length`).
  Each member runs on a synthesized `SubAgentInstance(id: task.id,
  subAgentSpecId: spec.name, parentSessionId: 'swarm', totalRuns: 0)`.
  traces: AgentSwarm.fr2
- **FR-003**: The system MUST satisfy this requirement: `allCompleted` (default): await every member; `status ==
  completed` iff every member's dispatch status is `completed`, else
  `partialFailure`; `results` in TASK order; `completedCount` = successful
  members; `winner` null.
  traces: AgentSwarm.fr3
- **FR-004**: The system MUST satisfy this requirement: `firstCompleted`: the first member to finish with dispatch
  status `completed` wins — `status == firstCompleted`, `winner` set,
  `results == [winner]`, `completedCount == 1`. If every member finishes
  without a single completion: `partialFailure`, `winner` null, all
  results, `completedCount == 0`. Non-winning members are NOT cancelled
  (documented; they run to completion detached).
  traces: AgentSwarm.fr4
- **FR-005**: The system MUST satisfy this requirement: `quorum`: `quorum` (k) is REQUIRED for this strategy and
  must satisfy `1 <= k <= tasks.length` (`ArgumentError` otherwise, as is
  a missing k). The k-th successful member triggers
  `status == quorumReached` with `completedCount == k` and the
  completion-ordered results collected up to and including that member;
  if all members finish with fewer than k successes: `quorumFailed` with
  all results and the true success count.
  traces: AgentSwarm.fr5
- **FR-006**: The system MUST satisfy this requirement: Pass-through wiring: `onEvent`, `clock`, `adminGranted`
  forwarded to every member dispatch; member `MissionStarted.missionId ==
  task.id` (the caller can attribute every event to its swarm member).
  traces: AgentSwarm.fr6
- **FR-007**: The system MUST satisfy this requirement: Empty swarm is a caller bug: `run(tasks: [])` throws
  `ArgumentError`.
  traces: AgentSwarm.fr7
- **FR-008**: The system MUST satisfy this requirement: Gates: `dart analyze --fatal-infos` clean; `dart test` green
  (baseline 937/2 at `52ee56a` + new tests).
  traces: AgentSwarm.fr8

## Verification

- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — baseline + new tests pass, 0 new failures

## Out of scope

- Member cancellation / abort propagation (Dart futures are not
  cancellable; an engine-level cancellation token is future work).
- Retry/re-dispatch policies for failed members (a supervision layer, not
  a swarm).
- Inter-member communication (results never cross members — isolation is
  spec 070's contract).
- Swarm-level budgets (members carry their own spec budgets).
- New EngineEvent subtypes (FR-006 documents the pass-through instead).

## Acceptance Scenarios

> Derived verbatim from the feature's pinned regression suite.
> Behaviors are inherited-green: the cited tests pass unmodified in
> the repo suite (dart test, 1201 passing).
1. **Given** the feature implementation under its clean-architecture seams **When** members dispatch concurrently (overlap provable) **Then** the pinned regression test passes (`test/engine/agent_swarm_test.dart`).
   **Type**: acceptance
2. **Given** the feature implementation under its clean-architecture seams **When** allCompleted returns a barrier over task-ordered results **Then** the pinned regression test passes (`test/engine/agent_swarm_test.dart`).
   **Type**: acceptance
3. **Given** the feature implementation under its clean-architecture seams **When** allCompleted reports partialFailure when a member fails **Then** the pinned regression test passes (`test/engine/agent_swarm_test.dart`).
   **Type**: acceptance
4. **Given** the feature implementation under its clean-architecture seams **When** firstCompleted wins on completion order, not submission order **Then** the pinned regression test passes (`test/engine/agent_swarm_test.dart`).
   **Type**: acceptance
5. **Given** the feature implementation under its clean-architecture seams **When** firstCompleted without any success degrades to partialFailure **Then** the pinned regression test passes (`test/engine/agent_swarm_test.dart`).
   **Type**: acceptance
6. **Given** the feature implementation under its clean-architecture seams **When** quorum reached on the k-th success **Then** the pinned regression test passes (`test/engine/agent_swarm_test.dart`).
   **Type**: acceptance
7. **Given** the feature implementation under its clean-architecture seams **When** quorum unmet fails with the true success count **Then** the pinned regression test passes (`test/engine/agent_swarm_test.dart`).
   **Type**: acceptance
8. **Given** the feature implementation under its clean-architecture seams **When** validation rejects empty, duplicate-id, and bad-quorum runs **Then** the pinned regression test passes (`test/engine/agent_swarm_test.dart`).
   **Type**: acceptance
9. **Given** the feature implementation under its clean-architecture seams **When** single-task swarm runs a real child mission end-to-end **Then** the pinned regression test passes (`test/engine/agent_swarm_test.dart`).
   **Type**: acceptance
10. **Given** the feature implementation under its clean-architecture seams **When** value objects carry house semantics **Then** the pinned regression test passes (`test/engine/agent_swarm_test.dart`).
   **Type**: acceptance

## Layer Contracts

**Domain**:

- `AgentSwarm`: `fr1(...) -> Result`, `fr2(...) -> Result`, `fr3(...) -> Result`, `fr4(...) -> Result`, `fr5(...) -> Result`, `fr6(...) -> Result`, `fr7(...) -> Result`, `fr8(...) -> Result`

