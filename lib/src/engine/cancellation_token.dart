// HAND-CURATED — engine-level cooperative cancellation (issue #140).
//
// Dart futures cannot be aborted, so cancellation in the engine is
// COOPERATIVE: an owner signals a [CancellationToken] — e.g. an AgentSwarm
// cancelling its non-winning members after first/quorum success (spec 072) —
// and the bearer (a MissionRunner turn loop) observes the signal at its own
// checkpoints, the mission turn boundaries, and stops itself. The turn in
// flight when cancel() lands always completes.
//
// Not exported from lib/zuraffa_agent.dart — consistent with the sibling
// engine runtimes (mission_runner.dart, sub_agent_dispatch.dart).

import 'dart:async';

/// A cooperative cancellation signal.
///
/// One token per bearer (one mission, one swarm member). The owner calls
/// [cancel] once; the bearer polls [isCancelled] at its checkpoints or
/// awaits [whenCancelled] instead of polling. Signalling is immediate,
/// idempotent, and never errors.
class CancellationToken {
  final Completer<void> _completer = Completer<void>();

  /// Whether [cancel] has been called at least once.
  bool get isCancelled => _completer.isCompleted;

  /// Resolves the first time [cancel] is called — immediately for late
  /// awaiters — and never errors.
  Future<void> get whenCancelled => _completer.future;

  /// Signals cancellation. Idempotent: further calls are no-ops.
  void cancel() {
    if (!_completer.isCompleted) _completer.complete();
  }

  @override
  String toString() =>
      'CancellationToken(${isCancelled ? 'cancelled' : 'active'})';
}
