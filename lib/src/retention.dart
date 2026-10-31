// Retention & TTL policy for the durable stores (issue #135) — the
// aggregation layer.
//
// [RetentionSweep] is the mission-runner hook; [RetentionCoordinator] is
// the stock implementation bundling the four stores with their policies
// (+ [UsageLedgerBinding] for the immutable ledger, [PruneReport] for the
// aggregated outcome).
//
// The pure policy core — [RetentionPolicy], [PruneCandidate],
// [PruneResult], [selectPruneIds] and the candidate/size helpers — lives
// in retention_policy.dart and is re-exported here, so the public API
// (lib/zuraffa_agent.dart exports this file) is unchanged while the stores
// import the policy file directly: no import cycles with the four stores
// this file aggregates.
//
// Pure Dart: no dart:io (constitution VII). The file I/O for backup
// envelopes lives in session_backup.dart.

import 'engine/events/engine_event_log.dart';
import 'llm/episodic_memory_store.dart';
import 'retention_policy.dart';
import 'session_storage.dart';
import 'usage_ledger.dart';

export 'retention_policy.dart';

/// The mission-runner prune hook (issue #135): anything that can sweep
/// stale state between missions. [RetentionCoordinator] is the stock
/// implementation; tests inject fakes.
abstract interface class RetentionSweep {
  /// Sweeps stale state; runs between missions.
  Future<void> prune();
}

/// Binds a [UsageLedger] projection to its policy. The ledger is an
/// immutable value object (spec 083) — it cannot prune itself in place —
/// so the owner supplies a [ledger] getter and a [writeback] that receives
/// the pruned projection.
final class UsageLedgerBinding {
  /// Creates an usage ledger binding.
  const UsageLedgerBinding({
    required this.ledger,
    required this.writeback,
    required this.policy,
  });

  /// The ledger callback.
  final UsageLedger Function() ledger;

  /// The writeback callback.
  final void Function(UsageLedger) writeback;

  /// The policy.
  final RetentionPolicy policy;
}

/// Aggregated outcome of one [RetentionCoordinator] sweep.
class PruneReport {
  /// Creates a prune report.
  const PruneReport({required this.results});

  /// The results.
  final List<PruneResult> results;

  /// The total removed count.
  int get totalRemovedCount =>
      results.fold(0, (sum, r) => sum + r.removedCount);

  /// The total removed bytes.
  int get totalRemovedBytes =>
      results.fold(0, (sum, r) => sum + r.removedBytes);
}

/// The stock [RetentionSweep] (issue #135): runs `prune()` over every
/// wired store with its policy. A store axis left out (null store or null
/// policy) is simply not swept; usage-ledger bindings always run.
final class RetentionCoordinator implements RetentionSweep {
  /// Creates a retention coordinator.
  RetentionCoordinator({
    this.sessionStorage,
    this.sessionPolicy,
    this.episodicMemoryStore,
    this.memoryPolicy,
    this.usageLedgers = const [],
    this.eventLog,
    this.eventPolicy,
    this.clock,
  });

  /// The session storage.
  final SessionStorage? sessionStorage;

  /// The session policy.
  final RetentionPolicy? sessionPolicy;

  /// The episodic memory store.
  final EpisodicMemoryStore? episodicMemoryStore;

  /// The memory policy.
  final RetentionPolicy? memoryPolicy;

  /// The usage ledgers.
  final List<UsageLedgerBinding> usageLedgers;

  /// The event log.
  final EngineEventLog? eventLog;

  /// The event policy.
  final RetentionPolicy? eventPolicy;

  /// Injectable clock for maxAge cutoffs (defaults to `DateTime.now`).
  final DateTime Function()? clock;

  @override
  Future<PruneReport> prune() async {
    final now = (clock ?? DateTime.now)();
    final results = <PruneResult>[];

    final storage = sessionStorage;
    final sPolicy = sessionPolicy;
    if (storage != null && sPolicy != null) {
      results.add(await storage.prune(sPolicy, now: now));
    }

    final memory = episodicMemoryStore;
    final mPolicy = memoryPolicy;
    if (memory != null && mPolicy != null) {
      results.add(await memory.prune(mPolicy, now: now));
    }

    for (final binding in usageLedgers) {
      binding.writeback(binding.ledger().prune(binding.policy, now: now));
    }

    final log = eventLog;
    final ePolicy = eventPolicy;
    if (log != null && ePolicy != null) {
      results.add(log.prune(ePolicy, now: now));
    }

    return PruneReport(results: List.unmodifiable(results));
  }
}
