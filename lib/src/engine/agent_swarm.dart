// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// Spec 072 — agent swarm.
//
// Fan-out + aggregation over the sub-agent dispatch runtime (spec 070):
// a set of SwarmTasks dispatches CONCURRENTLY (every member starts before
// any is awaited — the overlap is provable), and the swarm aggregates the
// outcomes under one of three strategies:
//
//   allCompleted  — barrier: wait for everyone; completed iff all completed
//   firstCompleted — first member to finish successfully wins
//   quorum(k)     — the k-th success is enough
//
// Design stance (documented in specs/072-agent-swarm/spec.md, updated by
// issue #140): a swarm is fan-out + aggregation, NOT supervision. It does
// not RETRY failures and invents no new EngineEvent subtypes. Since #140 it
// DOES cancel losing members COOPERATIVELY on early-return strategies: each
// member runs under its own CancellationToken, and once first/quorum success
// lands the swarm signals the tokens of members that have not finished. Dart
// futures are not abortable, so a member stops at its NEXT mission turn
// boundary (MissionRunner) — the turn in flight always completes — and a
// member that never observes the token still runs to completion detached.
// Member events flow to the caller's sink keyed by task id, so every event
// is attributable to its swarm member.
//
// Not exported from lib/zuraffa_agent.dart — consistent with the sibling
// engine runtimes.

import 'dart:async';

import '../domain/entities/sub_agent_instance/sub_agent_instance.dart';
import '../domain/entities/sub_agent_spec/sub_agent_spec.dart';
import 'cancellation_token.dart';
import 'events/engine_event.dart';
import 'sub_agent_dispatch.dart';

/// How a swarm aggregates its members' outcomes.
enum SwarmStrategy {
  /// Barrier: wait for every member; the swarm completes iff all did.
  allCompleted,

  /// The first member to finish successfully wins.
  firstCompleted,

  /// The k-th successful member is enough (k = the `quorum` parameter).
  quorum,
}

/// Terminal status of a swarm run.
enum SwarmStatus {
  /// allCompleted: every member completed.
  completed,

  /// Not every member completed (allCompleted with failures,
  /// firstCompleted with no success at all).
  partialFailure,

  /// firstCompleted: a winner was determined.
  firstCompleted,

  /// quorum: k successes arrived.
  quorumReached,

  /// quorum: all members finished with fewer than k successes.
  quorumFailed,
}

/// One swarm member: the sub-agent [spec] to run and the [mission] to give
/// it. [id] is the member's identity — the synthesized instance id and the
/// event-attribution key — and must be unique within a swarm.
class SwarmTask {
  final String id;
  final SubAgentSpec spec;
  final String mission;

  const SwarmTask({
    required this.id,
    required this.spec,
    required this.mission,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SwarmTask &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          spec == other.spec &&
          mission == other.mission);

  @override
  int get hashCode => Object.hash(id, spec, mission);

  @override
  String toString() =>
      'SwarmTask(id: $id, spec: ${spec.name}, mission: $mission)';
}

/// One member's outcome inside a swarm run.
class SwarmTaskResult {
  final String taskId;
  final String specName;
  final SubAgentDispatchStatus status;
  final String? summary;

  const SwarmTaskResult({
    required this.taskId,
    required this.specName,
    required this.status,
    required this.summary,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SwarmTaskResult &&
          runtimeType == other.runtimeType &&
          taskId == other.taskId &&
          specName == other.specName &&
          status == other.status &&
          summary == other.summary);

  @override
  int get hashCode => Object.hash(taskId, specName, status, summary);

  @override
  String toString() =>
      'SwarmTaskResult(taskId: $taskId, specName: $specName, '
      'status: ${status.name}, summary: $summary)';
}

/// Outcome of a swarm run: the [strategy] used, terminal [status], the
/// member [results] (task order for barriers, completion order for early
//  strategies), the [winner] on firstCompleted, and the [completedCount]
/// of successful members.
class SwarmResult {
  final SwarmStrategy strategy;
  final SwarmStatus status;
  final List<SwarmTaskResult> results;
  final SwarmTaskResult? winner;
  final int completedCount;

  SwarmResult({
    required this.strategy,
    required this.status,
    required List<SwarmTaskResult> results,
    this.winner,
    required this.completedCount,
  }) : results = List.unmodifiable(results);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SwarmResult &&
          runtimeType == other.runtimeType &&
          strategy == other.strategy &&
          status == other.status &&
          _listEq(results, other.results) &&
          winner == other.winner &&
          completedCount == other.completedCount);

  static bool _listEq(List<SwarmTaskResult> a, List<SwarmTaskResult> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    strategy,
    status,
    Object.hashAll(results),
    winner,
    completedCount,
  );

  @override
  String toString() =>
      'SwarmResult(strategy: ${strategy.name}, status: ${status.name}, '
      'members: ${results.length}, completed: $completedCount'
      '${winner != null ? ', winner: ${winner!.taskId}' : ''})';
}

/// Runs agent swarms: concurrent fan-out over the sub-agent dispatch
/// service with strategy-based aggregation.
class AgentSwarm {
  AgentSwarm({required SubAgentDispatchService dispatchService})
    : _dispatchService = dispatchService;

  final SubAgentDispatchService _dispatchService;

  /// Runs [tasks] as one swarm under [strategy].
  ///
  /// Every member dispatch starts EAGERLY — all futures are created before
  /// any is awaited, so members genuinely overlap. Each member runs on a
  /// synthesized instance (`id: task.id`, `parentSessionId: 'swarm'`,
  /// fresh counters); [onEvent], [clock], and [adminGranted] forward to
  /// every member dispatch.
  ///
  /// `quorum` is required for [SwarmStrategy.quorum] and must satisfy
  /// `1 <= quorum <= tasks.length`.
  ///
  /// Cooperative cancellation (issue #140): every member runs under its own
  /// [CancellationToken], handed to the dispatch service and observable by
  /// the member's mission loop. On [SwarmStrategy.firstCompleted] and
  /// [SwarmStrategy.quorum], once the winner/quorum lands the swarm signals
  /// every member that has not yet finished; a cooperative member stops at
  /// its next mission turn boundary. [SwarmStrategy.allCompleted] waits for
  /// everyone and never signals. Members that ignore the token (or finish
  /// between checkpoints) still run to completion detached — their late
  /// results are simply dropped, as before.
  Future<SwarmResult> run({
    required List<SwarmTask> tasks,
    SwarmStrategy strategy = SwarmStrategy.allCompleted,
    int? quorum,
    void Function(EngineEvent)? onEvent,
    DateTime Function()? clock,
    bool adminGranted = false,
  }) async {
    if (tasks.isEmpty) {
      throw ArgumentError.value(
        tasks,
        'tasks',
        'a swarm needs at least one task',
      );
    }
    final ids = tasks.map((t) => t.id).toSet();
    if (ids.length != tasks.length) {
      throw ArgumentError.value(
        tasks,
        'tasks',
        'task ids must be unique — member instances key on them',
      );
    }
    if (strategy == SwarmStrategy.quorum) {
      if (quorum == null) {
        throw ArgumentError.value(
          quorum,
          'quorum',
          'quorum strategy requires a quorum size',
        );
      }
      if (quorum < 1 || quorum > tasks.length) {
        throw ArgumentError.value(
          quorum,
          'quorum',
          'quorum must be between 1 and the task count (${tasks.length})',
        );
      }
    }

    // One cancellation token per member (issue #140): the swarm owns the
    // signals and fires them on early-return aggregation; the member's
    // mission loop observes them at its turn boundaries.
    final tokens = {for (final task in tasks) task.id: CancellationToken()};

    // Eager fan-out: every member dispatch is CALLED here, before any
    // await — this is what makes the overlap in FR-002 provable.
    final futures = [
      for (final task in tasks)
        _runMember(
          task,
          onEvent: onEvent,
          clock: clock,
          adminGranted: adminGranted,
          cancellationToken: tokens[task.id],
        ),
    ];

    if (strategy == SwarmStrategy.allCompleted) {
      final results = await Future.wait(futures);
      final completedCount = results
          .where((r) => r.status == SubAgentDispatchStatus.completed)
          .length;
      return SwarmResult(
        strategy: strategy,
        status: completedCount == results.length
            ? SwarmStatus.completed
            : SwarmStatus.partialFailure,
        results: results,
        winner: null,
        completedCount: completedCount,
      );
    }

    // firstCompleted / quorum: process members as they finish.
    final completer = Completer<SwarmResult>();
    final collected = <SwarmTaskResult>[];
    var successes = 0;

    // Cooperative cancellation (issue #140): once the swarm returns early,
    // signal every member that has not yet delivered a result. Members that
    // already finished (success or failure) keep their token untouched.
    void cancelOutstanding() {
      final finished = collected.map((r) => r.taskId).toSet();
      for (final entry in tokens.entries) {
        if (!finished.contains(entry.key)) entry.value.cancel();
      }
    }

    StreamSubscription<SwarmTaskResult>? subscription;
    subscription = Stream.fromFutures(futures).listen(
      (result) {
        collected.add(result);
        if (result.status != SubAgentDispatchStatus.completed) {
          return;
        }
        successes++;
        if (strategy == SwarmStrategy.firstCompleted &&
            !completer.isCompleted) {
          subscription?.cancel();
          cancelOutstanding();
          completer.complete(
            SwarmResult(
              strategy: strategy,
              status: SwarmStatus.firstCompleted,
              results: [result],
              winner: result,
              completedCount: 1,
            ),
          );
        } else if (strategy == SwarmStrategy.quorum &&
            successes == quorum &&
            !completer.isCompleted) {
          subscription?.cancel();
          cancelOutstanding();
          completer.complete(
            SwarmResult(
              strategy: strategy,
              status: SwarmStatus.quorumReached,
              results: List.of(collected),
              winner: null,
              completedCount: successes,
            ),
          );
        }
      },
      onDone: () {
        if (completer.isCompleted) return;
        completer.complete(
          SwarmResult(
            strategy: strategy,
            status: strategy == SwarmStrategy.firstCompleted
                ? SwarmStatus.partialFailure
                : SwarmStatus.quorumFailed,
            results: List.of(collected),
            winner: null,
            completedCount: successes,
          ),
        );
      },
      onError: (Object e, StackTrace st) {
        // A member blew up out-of-band: the swarm surface propagates the
        // error, and the still-running members are signalled so they stop
        // at their next boundary instead of burning budget detached.
        cancelOutstanding();
        if (!completer.isCompleted) completer.completeError(e, st);
      },
    );
    return completer.future;
  }

  Future<SwarmTaskResult> _runMember(
    SwarmTask task, {
    void Function(EngineEvent)? onEvent,
    DateTime Function()? clock,
    bool adminGranted = false,
    CancellationToken? cancellationToken,
  }) async {
    final instance = SubAgentInstance(
      id: task.id,
      subAgentSpecId: task.spec.name,
      parentSessionId: 'swarm',
      totalRuns: 0,
    );
    final dispatch = await _dispatchService.dispatch(
      spec: task.spec,
      mission: task.mission,
      instance: instance,
      onEvent: onEvent,
      clock: clock,
      adminGranted: adminGranted,
      cancellationToken: cancellationToken,
    );
    return SwarmTaskResult(
      taskId: task.id,
      specName: task.spec.name,
      status: dispatch.status,
      summary: dispatch.resultSummary,
    );
  }
}
