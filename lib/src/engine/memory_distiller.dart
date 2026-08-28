// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// Spec 077 — memory distiller: automatic promotion session → long-term.
//
// The distiller is the automatic bridge spec 073's manual promote() left
// missing: scan a session's memory, promote the high-salience learnings
// into long-term memory, report exactly what happened and why.
//
// Policy (DistillationPolicy):
//   - salience gate: record must reach the threshold (default 0.7) —
//     the promotion price.
//   - duplicate guard: normalized content (trim + case-fold) already in
//     long-term → skip, knowledge must not duplicate. Checked against the
//     LIVE long-term store, so same-content session siblings dedupe
//     against each other mid-run for free.
//   - cap: maxPerSession bounds promotions per run (best first).
//
// Ranking among candidates: salience desc, then createdAt asc (older
// first — FIFO stability), then session insertion order (deterministic).
//
// distill() is an explicit call (session end / checkpoint / cron) — the
// honest seam for a synchronous engine. Idempotent for records already in
// long-term (duplicates never re-promote); overflow left under a
// maxPerSession cap may re-promote on a second run.
//
// The distiller only touches AgentMemorySystem's public surface — over
// the 076 persistent stores, distilled knowledge is durable immediately.

import 'agent_memory.dart';

/// Tuning knobs for one distillation run (spec 077 FR-001).
class DistillationPolicy {
  /// Minimum salience a session record must reach to be promoted.
  /// Boundary is inclusive: `salience == threshold` promotes.
  final double salienceThreshold;

  /// Maximum promotions per distill run; null means uncapped.
  final int? maxPerSession;

  DistillationPolicy({
    this.salienceThreshold = 0.7,
    this.maxPerSession,
  }) {
    if (salienceThreshold < 0.0 || salienceThreshold > 1.0) {
      throw ArgumentError.value(
          salienceThreshold, 'salienceThreshold', 'must be within 0.0..1.0');
    }
    if (maxPerSession != null && maxPerSession! < 1) {
      throw ArgumentError.value(
          maxPerSession, 'maxPerSession', 'must be at least 1 when set');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DistillationPolicy &&
          runtimeType == other.runtimeType &&
          salienceThreshold == other.salienceThreshold &&
          maxPerSession == other.maxPerSession);

  @override
  int get hashCode => Object.hash(salienceThreshold, maxPerSession);

  @override
  String toString() =>
      'DistillationPolicy(salienceThreshold: $salienceThreshold, '
      'maxPerSession: $maxPerSession)';
}

/// Why a session record was NOT promoted (spec 077 FR-004..FR-006).
enum SkipReason {
  /// Salience below the policy threshold.
  belowThreshold,

  /// Normalized content already known to long-term memory.
  duplicateOfLongTerm,

  /// A qualified candidate, but the per-session promotion cap was spent.
  capReached,
}

/// One skipped record with its typed reason.
class SkippedRecord {
  final String id;
  final SkipReason reason;

  const SkippedRecord(this.id, this.reason);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SkippedRecord &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          reason == other.reason);

  @override
  int get hashCode => Object.hash(id, reason);

  @override
  String toString() => 'SkippedRecord($id, ${reason.name})';
}

/// Full accounting of one distillation run (spec 077 FR-009): every
/// snapshot record appears either in [promoted] or [skipped] — nothing
/// silently disappears.
class DistillationReport {
  /// Promoted record ids, in promotion (ranking) order.
  final List<String> promoted;

  /// Skipped records with typed reasons.
  final List<SkippedRecord> skipped;

  /// How many records remain in the session after the run.
  final int sessionRemaining;

  DistillationReport({
    required List<String> promoted,
    required List<SkippedRecord> skipped,
    required this.sessionRemaining,
  })  : promoted = List.unmodifiable(promoted),
        skipped = List.unmodifiable(skipped);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DistillationReport &&
          runtimeType == other.runtimeType &&
          _listEq(promoted, other.promoted) &&
          _listEq(skipped, other.skipped) &&
          sessionRemaining == other.sessionRemaining);

  static bool _listEq<T>(List<T> a, List<T> b) =>
      a.length == b.length &&
      List.generate(a.length, (i) => a[i] == b[i]).every((eq) => eq);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(promoted), Object.hashAll(skipped),
          sessionRemaining);

  @override
  String toString() =>
      'DistillationReport(promoted: $promoted, skipped: $skipped, '
      'sessionRemaining: $sessionRemaining)';
}

/// Auto-promotes session memories into long-term memory per policy
/// (spec 077).
class MemoryDistiller {
  MemoryDistiller({required this.system, DistillationPolicy? policy})
      : policy = policy ?? DistillationPolicy();

  /// The memory system being distilled — public surface only.
  final AgentMemorySystem system;

  /// The policy for this distiller.
  final DistillationPolicy policy;

  /// Distills [sessionId]'s memory: promotes qualified records into
  /// long-term memory and returns the full accounting.
  DistillationReport distill(String sessionId) {
    final snapshot = system.sessionMemory.forSession(sessionId);

    // Gate: partition into candidates and below-threshold skips.
    final candidates = <MemoryRecord>[];
    final skipped = <SkippedRecord>[];
    for (final record in snapshot) {
      if (record.salience >= policy.salienceThreshold) {
        candidates.add(record);
      } else {
        skipped.add(SkippedRecord(record.id, SkipReason.belowThreshold));
      }
    }

    // Rank: salience desc, createdAt asc (older first), then insertion
    // order — a total, deterministic order.
    final indexed = <(MemoryRecord, int)>[
      for (var i = 0; i < candidates.length; i++) (candidates[i], i),
    ]..sort((a, b) {
        final bySalience = b.$1.salience.compareTo(a.$1.salience);
        if (bySalience != 0) return bySalience;
        final byAge = a.$1.createdAt.compareTo(b.$1.createdAt);
        if (byAge != 0) return byAge;
        return a.$2.compareTo(b.$2);
      });

    // Seed known long-term contents ONCE, then grow it as records are
    // promoted — same-content siblings dedupe mid-run for free, without
    // re-walking the whole store per candidate (O(C·M) → O(C+M)).
    final knownLongTerm = <String>{
      for (final record in system.longTermMemory.all)
        _normalize(record.content),
    };

    final promoted = <String>[];
    var budget = policy.maxPerSession; // null = uncapped.
    for (final (record, _) in indexed) {
      // Duplicate check FIRST — a duplicate is not promotable even with
      // budget left, so the more informative reason wins.
      if (knownLongTerm.contains(_normalize(record.content))) {
        skipped.add(SkippedRecord(record.id, SkipReason.duplicateOfLongTerm));
        continue;
      }
      if (budget != null && budget <= 0) {
        skipped.add(SkippedRecord(record.id, SkipReason.capReached));
        continue;
      }
      system.promote(record.id); // facade semantics: identity preserved.
      knownLongTerm.add(_normalize(record.content)); // keep live for dedup.
      promoted.add(record.id);
      if (budget != null) budget--;
    }

    return DistillationReport(
      promoted: promoted,
      skipped: skipped,
      sessionRemaining:
          system.sessionMemory.forSession(sessionId).length,
    );
  }

  static String _normalize(String content) => content.trim().toLowerCase();
}
