# Implementation Plan: Agent swarm

**Branch**: `feat/spec-072-agent-swarm` | **Date**: 2026-08-29

## Summary

Fan-out + aggregation over spec 070's `SubAgentDispatchService`: eager
per-task futures, three aggregation strategies (barrier / first-success /
quorum), typed results, honest non-cancellation.

## Phase 1 — Design

### `lib/src/engine/agent_swarm.dart` (new)

```dart
enum SwarmStrategy { allCompleted, firstCompleted, quorum }
enum SwarmStatus { completed, partialFailure, firstCompleted, quorumReached, quorumFailed }

class SwarmTask { /* id, spec, mission; == / hashCode / toString */ }
class SwarmTaskResult { /* taskId, specName, status, summary; house pattern */ }
class SwarmResult { /* strategy, status, results, winner, completedCount; house pattern */ }

class AgentSwarm {
  AgentSwarm({required SubAgentDispatchService dispatchService});

  Future<SwarmResult> run({
    required List<SwarmTask> tasks,
    SwarmStrategy strategy = SwarmStrategy.allCompleted,
    int? quorum,
    void Function(EngineEvent)? onEvent,
    DateTime Function()? clock,
    bool adminGranted = false,
  });
}
```

- Validation: non-empty tasks; unique ids; quorum strategy requires
  `1 <= quorum <= tasks.length`.
- Fan-out: `final futures = [for (final t in tasks) _runMember(t)]` —
  ALL dispatches called before any await (FR-002's eager overlap).
- `allCompleted`: `Future.wait` → task-order results, aggregate status.
- `firstCompleted` / `quorum`: `Stream.fromFutures(futures)` + a
  `Completer<SwarmResult>`; count successes as they land; complete early on
  the strategy's trigger; `onDone` completes the failure shape when the
  stream exhausts. Early return cancels the subscription; remaining member
  futures are non-cancellable by design (documented — they complete
  harmlessly into the discarded stream; dispatch never throws, so no
  unhandled-error hazard).
- `_runMember`: synthesizes the instance, forwards onEvent/clock/
  adminGranted, maps `SubAgentDispatchResult` → `SwarmTaskResult`.

### Test doubles (`test/engine/agent_swarm_test.dart`)

- `ScriptedDispatchService extends SubAgentDispatchService` — overrides
  `dispatch` with per-instance-id scripts (`delay`, `status`, `summary`);
  counts in-flight dispatches (`active`, `maxActive`) for the overlap
  proof. Super ctor gets inert fakes (never reached).
- One REAL `SubAgentDispatchService` integration test (fake LLM +
  dispatcher): single-task swarm → the child mission actually runs.

## Phase 2 — TDD

1. RED: test file first (missing `agent_swarm.dart` compile failure).
2. GREEN: implement until green.
3. Deliberate mutants (cp-restored): M1 sequential fan-out (await each
   before starting next); M2 allCompleted ignores failures; M3
   firstCompleted returns tasks.first (submission order); M4 quorum counts
   all completions, not just successes; M5 winner never set on
   firstCompleted.
4. Gates + `tdd/verification.md`; commit; push; PR (base
   `feat/spec-070-sub-agent-dispatch` — stacked on #81, which stacks on
   #80).
