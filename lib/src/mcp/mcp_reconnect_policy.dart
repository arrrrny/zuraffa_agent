// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#15 (spec 015-mcp-client).
//
// McpReconnectPolicy — exponential-backoff-with-jitter for the SSE
// and stdio MCP clients. Pure Dart (no dart:io); tests inject a fake
// clock + fake delay so the backoff sequence is deterministic and
// observable.
//
// Spec 015 SC-002: SSE reconnects after connection drop within 5s.
// Spec 015 SC-003: stdio restarts after crash within 10s.
// Default policy: initial 100ms, factor 2, cap 1s, maxAttempts 8,
// deterministic jitter under a fixed seed — total wall-time under
// 5s for SSE; stdio uses a longer maxAttempts to land within 10s.

import 'dart:math' as math;

/// Function that returns the current time. Injected so tests don't
/// depend on wall-clock. Used by [ToolListingCache] and the MCP
/// clients for diagnostic timestamps — not by the reconnect policy
/// itself (the policy only needs a [McpDelay]).
typedef McpClock = DateTime Function();

/// Function that delays execution by the given duration. Injected so
/// tests can record the delays without actually sleeping.
typedef McpDelay = Future<void> Function(Duration);

/// Configuration for [McpReconnectPolicy].
class McpReconnectPolicyConfig {
  /// Initial backoff delay — first retry waits this long.
  final Duration initial;

  /// Multiplier applied to the previous delay each retry. `2.0` is
  /// classic exponential backoff.
  final double factor;

  /// Upper bound on a single delay.
  final Duration cap;

  /// Maximum number of attempts before the policy declares the client
  /// [McpClientState.failed].
  final int maxAttempts;

  /// Jitter amplitude — each delay is multiplied by `(1 - jitter) +
  /// rand.nextDouble() * 2 * jitter` so the actual delay is in
  /// `[delay * (1 - jitter), delay * (1 + jitter)]`. `0.0` disables
  /// jitter; `0.5` is the classic "decorrelated jitter" amplitude.
  final double jitter;

  const McpReconnectPolicyConfig({
    required this.initial,
    required this.factor,
    required this.cap,
    required this.maxAttempts,
    this.jitter = 0.0,
  });

  /// SSE policy — fast initial, low maxAttempts (drop within 5s).
  static const sse = McpReconnectPolicyConfig(
    initial: Duration(milliseconds: 100),
    factor: 2.0,
    cap: Duration(seconds: 1),
    maxAttempts: 8,
    jitter: 0.0, // deterministic in tests; flip to 0.3 in production
  );

  /// stdio policy — slower cap, more attempts (land within 10s).
  static const stdio = McpReconnectPolicyConfig(
    initial: Duration(milliseconds: 200),
    factor: 2.0,
    cap: Duration(seconds: 2),
    maxAttempts: 6,
    jitter: 0.0,
  );
}

/// The reconnect policy — given a [McpReconnectPolicyConfig], an
/// injected [McpClock], an injected [McpDelay], and a deterministic
/// RNG seed, computes the next backoff delay and tells the caller
/// whether to retry or give up.
class McpReconnectPolicy {
  final McpReconnectPolicyConfig config;
  final McpDelay _delay;
  final math.Random _rng;

  int _attempt = 0;

  McpReconnectPolicy({
    required this.config,
    required McpDelay delay,
    int seed = 0,
  })  : _delay = delay,
        _rng = math.Random(seed);

  /// Number of attempts made so far. Resets to 0 after a successful
  /// reconnect.
  int get attempt => _attempt;

  /// True once [config.maxAttempts] has been exhausted.
  bool get exhausted => _attempt >= config.maxAttempts;

  /// Compute and apply the next backoff delay. Returns true if the
  /// caller should retry, false if the policy is exhausted.
  ///
  /// Throws [StateError] if called after [exhausted] (programmer error
  /// — callers must check [exhausted] first).
  Future<bool> nextBackoff() async {
    if (exhausted) {
      throw StateError(
        'McpReconnectPolicy.nextBackoff called after exhaustion '
        '(attempt=$_attempt, max=${config.maxAttempts})',
      );
    }
    _attempt += 1;
    final raw = config.initial.inMicroseconds *
        math.pow(config.factor, _attempt - 1);
    final capped = raw.clamp(0, config.cap.inMicroseconds).toDouble();
    var delayMicros = capped;
    if (config.jitter > 0.0) {
      final jitterScale = (1 - config.jitter) + _rng.nextDouble() * 2 * config.jitter;
      delayMicros = (capped * jitterScale).clamp(0, config.cap.inMicroseconds).toDouble();
    }
    await _delay(Duration(microseconds: delayMicros.toInt()));
    return true;
  }

  /// Reset the attempt counter — called by the client after a
  /// successful reconnect so the next drop starts the backoff from
  /// the initial delay.
  void reset() {
    _attempt = 0;
  }
}

/// A recorded sequence of delays applied by a [McpReconnectPolicy]
/// when the [McpDelay] is the recording fake from test/mcp.
class RecordedDelays {
  final List<Duration> delays;
  RecordedDelays(this.delays);
}
