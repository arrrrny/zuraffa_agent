// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#5 (R4 — providers & fallback).
//
// The CircuitBreaker value object + CircuitBreakerState enum — spec-exact
// from epic #1 §R4.3 (issue #5 body: "Fallback chain (supersedes
// arrrrny/dart_agent_core#1): ordered provider chain, circuit breaker
// (open/half-open/close with backoff), mid-stream restart policy, health
// snapshot").
//
// Modeled as an immutable snapshot with pure transition methods:
// `recordFailure`, `recordSuccess`, `tryHalfOpen` each return a NEW
// CircuitBreaker instance — the value object is never mutated in place.
// The engine (or a separate FallbackChain coordinator in a later PR) is
// responsible for calling the right transition at the right time; the
// breaker itself has no timers, no I/O, no shared mutable state.
//
// Pattern: plain Dart value object (no @Zorphy annotation) so the file
// compiles without running build_runner, same as AgentSession (PR #50),
// ToolResult (PR #49), AgentTool (PR #52), and StopPolicy (PR #47).
//
// Refined under specs/035-circuit-breaker (TDD): the recovery semantics
// the task names — shouldProbe(now), the read-only recovery-readiness
// predicate (the coordinator's "is the half-open probe due" question,
// with the same inclusive elapsed >= cooldown boundary tryHalfOpen
// uses), and the persistence contract (toJson/fromJson round-tripping
// all nine fields exactly: state as its name, Duration as microseconds,
// absent-never-fabricated timestamps, parse-time threshold validation —
// a restored open breaker continues its cooldown from the original
// openedAt, a mid-probe breaker resumes with partial counters). The
// transitions and reads above are unchanged.

/// State of a [CircuitBreaker] in the fallback chain.
///
/// - [closed] — normal operation. Requests pass through; consecutive
///   failures increment [CircuitBreaker.failureCount]. When
///   `failureCount >= failureThreshold`, the breaker trips to [open].
/// - [open] — tripped. Requests fail-fast (the engine skips this
///   provider and tries the next in the chain). After [CircuitBreaker.cooldown]
///   elapses since [CircuitBreaker.openedAt], the breaker transitions to
///   [halfOpen] (via [CircuitBreaker.tryHalfOpen]).
/// - [halfOpen] — probing. A limited number of trial requests are
///   allowed; success → [closed] (when halfOpenSuccesses ≥
///   halfOpenThreshold), failure → [open] (with reset).
enum CircuitBreakerState {
  closed,
  open,
  halfOpen;
}

/// CircuitBreaker value object (immutable snapshot).
///
/// Guards a single provider in the fallback chain: tracks its current
/// [state], the consecutive-failure counter ([failureCount]), the
/// trip threshold ([failureThreshold]), the cooldown [Duration] before
/// probing, and the half-open success counter ([halfOpenSuccesses]) with
/// its close threshold ([halfOpenThreshold]).
///
/// The value object is immutable — every transition method
/// ([recordFailure], [recordSuccess], [tryHalfOpen]) returns a new
/// snapshot. The engine or a `FallbackChain` coordinator is responsible
/// for calling the right transition at the right time.
class CircuitBreaker {
  /// Names the provider the breaker guards (e.g. "openai-compatible",
  /// "anthropic", "gemini"). Unique within a fallback chain.
  final String id;

  /// Current state of the breaker. Defaults to [CircuitBreakerState.closed].
  final CircuitBreakerState state;

  /// Consecutive failures observed in [CircuitBreakerState.closed]. Resets
  /// to 0 when the breaker closes from halfOpen. Does not increment in
  /// [CircuitBreakerState.open] (the breaker is already tripped).
  final int failureCount;

  /// Failures needed in [CircuitBreakerState.closed] to trip the breaker
  /// to [CircuitBreakerState.open]. Required — must be > 0.
  final int failureThreshold;

  /// When the breaker tripped to [CircuitBreakerState.open]. Null when
  /// the breaker is closed. Used by [tryHalfOpen] to compute cooldown
  /// elapsed.
  final DateTime? openedAt;

  /// Time the breaker stays in [CircuitBreakerState.open] before
  /// transitioning to [CircuitBreakerState.halfOpen]. Required — must
  /// be > Duration.zero.
  final Duration cooldown;

  /// Consecutive successes observed in [CircuitBreakerState.halfOpen].
  /// Resets to 0 when the breaker trips back to open from halfOpen.
  final int halfOpenSuccesses;

  /// Successes needed in [CircuitBreakerState.halfOpen] to close the
  /// breaker. Required — must be > 0.
  final int halfOpenThreshold;

  /// When the most recent failure happened, regardless of state. Used
  /// for health-snapshot reporting (R4.3 "health snapshot"). Null when
  /// the breaker has never observed a failure.
  final DateTime? lastFailureAt;

  const CircuitBreaker({
    required this.id,
    required this.failureThreshold,
    required this.cooldown,
    required this.halfOpenThreshold,
    this.state = CircuitBreakerState.closed,
    this.failureCount = 0,
    this.openedAt,
    this.halfOpenSuccesses = 0,
    this.lastFailureAt,
  });

  /// True when the breaker is in [CircuitBreakerState.open] — requests
  /// fail-fast.
  bool get isOpen => state == CircuitBreakerState.open;

  /// True when the breaker is in [CircuitBreakerState.closed] — normal
  /// operation.
  bool get isClosed => state == CircuitBreakerState.closed;

  /// True when the breaker is in [CircuitBreakerState.halfOpen] —
  /// probing with limited trial requests.
  bool get isHalfOpen => state == CircuitBreakerState.halfOpen;

  /// Recovery readiness (read-only): true iff the breaker is [open],
  /// has an [openedAt] anchor, and [now] is at or past the cooldown
  /// boundary (`now - openedAt >= cooldown`, inclusive — the same
  /// boundary [tryHalfOpen] transitions on). False in closed (nothing
  /// to recover), halfOpen (the probe is in flight, not due), and for
  /// an open breaker without an [openedAt] anchor (defensive).
  ///
  /// This is the read side of the scaffold's "the engine... is
  /// responsible for calling the right transition at the right time"
  /// contract: the coordinator asks shouldProbe, then calls
  /// [tryHalfOpen] itself. It never transitions the breaker.
  bool shouldProbe(DateTime now) {
    if (state != CircuitBreakerState.open || openedAt == null) {
      return false;
    }
    return now.difference(openedAt!) >= cooldown;
  }

  /// Record a failure observed at [at] (default: now). Returns a new
  /// immutable snapshot:
  /// - closed → open (when failureCount + 1 ≥ failureThreshold; sets
  ///   openedAt and lastFailureAt, keeps failureCount for context)
  /// - closed → closed (failureCount + 1, lastFailureAt updated)
  /// - halfOpen → open (resets halfOpenSuccesses to 0, sets openedAt
  ///   and lastFailureAt)
  /// - open → open (unchanged except lastFailureAt)
  CircuitBreaker recordFailure({DateTime? at}) {
    final ts = at ?? DateTime.now();
    switch (state) {
      case CircuitBreakerState.closed:
        final newCount = failureCount + 1;
        if (newCount >= failureThreshold) {
          return CircuitBreaker(
            id: id,
            failureThreshold: failureThreshold,
            cooldown: cooldown,
            halfOpenThreshold: halfOpenThreshold,
            state: CircuitBreakerState.open,
            failureCount: newCount,
            openedAt: ts,
            halfOpenSuccesses: 0,
            lastFailureAt: ts,
          );
        }
        return CircuitBreaker(
          id: id,
          failureThreshold: failureThreshold,
          cooldown: cooldown,
          halfOpenThreshold: halfOpenThreshold,
          state: CircuitBreakerState.closed,
          failureCount: newCount,
          openedAt: null,
          halfOpenSuccesses: 0,
          lastFailureAt: ts,
        );
      case CircuitBreakerState.halfOpen:
        return CircuitBreaker(
          id: id,
          failureThreshold: failureThreshold,
          cooldown: cooldown,
          halfOpenThreshold: halfOpenThreshold,
          state: CircuitBreakerState.open,
          failureCount: failureCount,
          openedAt: ts,
          halfOpenSuccesses: 0,
          lastFailureAt: ts,
        );
      case CircuitBreakerState.open:
        // Already tripped; just update lastFailureAt for health snapshot.
        return CircuitBreaker(
          id: id,
          failureThreshold: failureThreshold,
          cooldown: cooldown,
          halfOpenThreshold: halfOpenThreshold,
          state: CircuitBreakerState.open,
          failureCount: failureCount,
          openedAt: openedAt,
          halfOpenSuccesses: 0,
          lastFailureAt: ts,
        );
    }
  }

  /// Record a success. Returns a new immutable snapshot:
  /// - halfOpen → closed (when halfOpenSuccesses + 1 ≥ halfOpenThreshold;
  ///   resets failureCount, clears openedAt)
  /// - halfOpen → halfOpen (halfOpenSuccesses + 1)
  /// - closed → closed (resets failureCount to 0 — a success breaks the
  ///   failure streak)
  /// - open → open (unchanged — successes in open are not meaningful;
  ///   the breaker must transition to halfOpen via [tryHalfOpen] first)
  CircuitBreaker recordSuccess() {
    switch (state) {
      case CircuitBreakerState.halfOpen:
        final newSuccesses = halfOpenSuccesses + 1;
        if (newSuccesses >= halfOpenThreshold) {
          return CircuitBreaker(
            id: id,
            failureThreshold: failureThreshold,
            cooldown: cooldown,
            halfOpenThreshold: halfOpenThreshold,
            state: CircuitBreakerState.closed,
            failureCount: 0,
            openedAt: null,
            halfOpenSuccesses: 0,
            lastFailureAt: lastFailureAt,
          );
        }
        return CircuitBreaker(
          id: id,
          failureThreshold: failureThreshold,
          cooldown: cooldown,
          halfOpenThreshold: halfOpenThreshold,
          state: CircuitBreakerState.halfOpen,
          failureCount: failureCount,
          openedAt: openedAt,
          halfOpenSuccesses: newSuccesses,
          lastFailureAt: lastFailureAt,
        );
      case CircuitBreakerState.closed:
        // A success breaks the failure streak.
        return CircuitBreaker(
          id: id,
          failureThreshold: failureThreshold,
          cooldown: cooldown,
          halfOpenThreshold: halfOpenThreshold,
          state: CircuitBreakerState.closed,
          failureCount: 0,
          openedAt: null,
          halfOpenSuccesses: 0,
          lastFailureAt: lastFailureAt,
        );
      case CircuitBreakerState.open:
        // Successes in open are not meaningful; the breaker must transition
        // to halfOpen via tryHalfOpen first.
        return this;
    }
  }

  /// Try to transition from [CircuitBreakerState.open] to
  /// [CircuitBreakerState.halfOpen] when [now] - [openedAt] >= [cooldown].
  /// Returns a new snapshot:
  /// - open → halfOpen (when cooldown elapsed)
  /// - open → open (when cooldown not yet elapsed)
  /// - halfOpen → halfOpen (unchanged)
  /// - closed → closed (unchanged)
  CircuitBreaker tryHalfOpen(DateTime now) {
    if (state != CircuitBreakerState.open || openedAt == null) {
      return this;
    }
    final elapsed = now.difference(openedAt!);
    if (elapsed < cooldown) {
      return this;
    }
    return CircuitBreaker(
      id: id,
      failureThreshold: failureThreshold,
      cooldown: cooldown,
      halfOpenThreshold: halfOpenThreshold,
      state: CircuitBreakerState.halfOpen,
      failureCount: failureCount,
      openedAt: openedAt,
      halfOpenSuccesses: 0,
      lastFailureAt: lastFailureAt,
    );
  }

  /// Serializes the breaker snapshot to a JSON map (persistence
  /// contract): `id`, `state` (state name), `failureCount`,
  /// `failureThreshold`, `cooldown` (exact microseconds),
  /// `halfOpenSuccesses`, `halfOpenThreshold` always; `openedAt`,
  /// `lastFailureAt` only when present (absent-never-fabricated,
  /// ISO-8601). A restored snapshot continues its cooldown from the
  /// original [openedAt].
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'state': state.name,
      'failureCount': failureCount,
      'failureThreshold': failureThreshold,
      'cooldown': cooldown.inMicroseconds,
      'halfOpenSuccesses': halfOpenSuccesses,
      'halfOpenThreshold': halfOpenThreshold,
    };
    if (openedAt != null) json['openedAt'] = openedAt!.toIso8601String();
    if (lastFailureAt != null) json['lastFailureAt'] = lastFailureAt!.toIso8601String();
    return json;
  }

  /// Parses a [CircuitBreaker] from its JSON shape (see [toJson]).
  /// Round-trips every state exactly (closed with counters, open with
  /// timestamps, mid-probe halfOpen with partial successes). Throws
  /// [ArgumentError] naming the field on: missing/ill-typed required
  /// fields, an unknown state string, negative counters, thresholds
  /// below 1, a non-positive cooldown, or unparseable timestamps —
  /// never a silent default (a defaulted threshold would silently
  /// change trip behavior).
  factory CircuitBreaker.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    if (idRaw is! String || idRaw.isEmpty) {
      throw ArgumentError.value(idRaw, 'id', 'CircuitBreaker.id must be a non-empty string');
    }

    int requireInt(String key, {int min = 0}) {
      final value = json[key];
      if (value is! int || value < min) {
        throw ArgumentError.value(value, key, 'CircuitBreaker.$key must be an int >= $min');
      }
      return value;
    }

    final failureThreshold = requireInt('failureThreshold', min: 1);
    final halfOpenThreshold = requireInt('halfOpenThreshold', min: 1);
    final failureCount = requireInt('failureCount');
    final halfOpenSuccesses = requireInt('halfOpenSuccesses');

    final cooldownRaw = json['cooldown'];
    if (cooldownRaw is! int || cooldownRaw <= 0) {
      throw ArgumentError.value(cooldownRaw, 'cooldown', 'CircuitBreaker.cooldown must be positive microseconds');
    }
    final cooldown = Duration(microseconds: cooldownRaw);

    final stateRaw = json['state'] ?? 'closed';
    if (stateRaw is! String) {
      throw ArgumentError.value(stateRaw, 'state', 'CircuitBreaker.state must be a state-name string');
    }
    final state = switch (stateRaw) {
      'closed' => CircuitBreakerState.closed,
      'open' => CircuitBreakerState.open,
      'halfOpen' => CircuitBreakerState.halfOpen,
      _ => throw ArgumentError.value(
          stateRaw, 'state', 'unknown CircuitBreakerState — expected closed, open or halfOpen'),
    };

    DateTime? optionalTimestamp(String key) {
      final value = json[key];
      if (value == null) return null;
      if (value is! String) {
        throw ArgumentError.value(value, key, 'CircuitBreaker.$key must be an ISO-8601 string when present');
      }
      final parsed = DateTime.tryParse(value);
      if (parsed == null) {
        throw ArgumentError.value(value, key, 'CircuitBreaker.$key is not a parseable ISO-8601 timestamp');
      }
      return parsed;
    }

    return CircuitBreaker(
      id: idRaw,
      failureThreshold: failureThreshold,
      cooldown: cooldown,
      halfOpenThreshold: halfOpenThreshold,
      state: state,
      failureCount: failureCount,
      openedAt: optionalTimestamp('openedAt'),
      halfOpenSuccesses: halfOpenSuccesses,
      lastFailureAt: optionalTimestamp('lastFailureAt'),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CircuitBreaker &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          state == other.state &&
          failureCount == other.failureCount &&
          failureThreshold == other.failureThreshold &&
          openedAt == other.openedAt &&
          cooldown == other.cooldown &&
          halfOpenSuccesses == other.halfOpenSuccesses &&
          halfOpenThreshold == other.halfOpenThreshold &&
          lastFailureAt == other.lastFailureAt);

  @override
  int get hashCode => Object.hash(
        id,
        state,
        failureCount,
        failureThreshold,
        openedAt,
        cooldown,
        halfOpenSuccesses,
        halfOpenThreshold,
        lastFailureAt,
      );

  @override
  String toString() =>
      'CircuitBreaker(id: $id, state: $state, failureCount: $failureCount/$failureThreshold, '
      'halfOpenSuccesses: $halfOpenSuccesses/$halfOpenThreshold, openedAt: $openedAt, '
      'cooldown: $cooldown, lastFailureAt: $lastFailureAt)';
}
