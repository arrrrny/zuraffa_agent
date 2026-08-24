// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#7 (R6 — eval harness: pass@k unbiased
// estimator).
//
// The PassAtK value object — spec-exact from epic #1 §R6.2 (issue #7
// body: "Metrics: pass@k (unbiased estimator), pass^k (empirical);
// graders: exact / schema / model-judge"). Implements the unbiased
// pass@k estimator from Chen et al. 2021 (Codeforces / HumanEval):
//
//   pass@k = E[ 1 - C(n - c, k) / C(n, k) ]
//
// where n = total samples drawn, c = correct samples (c ≤ n), k =
// draw count for the pass@k evaluation (k ≤ n). When n - c < k, every
// k-subset includes at least one correct sample, so pass@k = 1.0.
//
// Pure deterministic function — no LLM, no I/O, no randomness. The
// repo doesn't yet ship a record/replay harness; this PR adds the
// metric that the harness will emit per mission.
//
// Pattern: plain Dart value object (no @Zorphy annotation) so the file
// compiles without running build_runner, same as AgentSession (PR #50),
// ToolResult (PR #49), AgentTool (PR #52), CircuitBreaker (PR #53), and
// SubAgentSpec (PR #54).

/// PassAtK value object — the unbiased pass@k estimator (Chen et al. 2021).
///
/// Captures a single pass@k computation: the inputs (n total samples,
/// c correct samples, k draw count) and the computed `value` (the
/// unbiased estimator, 0.0 to 1.0). The value is precomputed at
/// construction by the static [compute] factory.
class PassAtK {
  /// Total samples drawn. Must be ≥ 1.
  final int n;

  /// Correct samples (c ≤ n). Must be ≥ 0.
  final int c;

  /// Draw count for the pass@k evaluation (1 ≤ k ≤ n).
  final int k;

  /// The computed unbiased pass@k estimator (0.0 to 1.0). Precomputed
  /// at construction; derived from [n], [c], [k] so equality on the
  /// input triple implies value equality.
  final double value;

  const PassAtK._({
    required this.n,
    required this.c,
    required this.k,
    required this.value,
  });

  /// Compute the unbiased pass@k estimator for the given inputs.
  ///
  /// Validates: `n ≥ 1`, `0 ≤ c ≤ n`, `1 ≤ k ≤ n`. Throws
  /// [ArgumentError] on invalid input.
  ///
  /// Formula (Chen et al. 2021):
  ///   pass@k = 1 - C(n - c, k) / C(n, k)
  /// where C(a, b) is the binomial coefficient "a choose b".
  ///
  /// When `n - c < k`, every k-subset includes at least one correct
  /// sample, so pass@k = 1.0.
  static PassAtK compute({required int n, required int c, required int k}) {
    if (n < 1) {
      throw ArgumentError.value(n, 'n', 'must be ≥ 1');
    }
    if (c < 0) {
      throw ArgumentError.value(c, 'c', 'must be ≥ 0');
    }
    if (c > n) {
      throw ArgumentError.value(c, 'c', 'must be ≤ n (=$n)');
    }
    if (k < 1) {
      throw ArgumentError.value(k, 'k', 'must be ≥ 1');
    }
    if (k > n) {
      throw ArgumentError.value(k, 'k', 'must be ≤ n (=$n)');
    }
    final value = _estimator(n, c, k);
    return PassAtK._(n: n, c: c, k: k, value: value);
  }

  static double _estimator(int n, int c, int k) {
    // If c == 0, no correct samples → pass@k = 0.
    if (c == 0) return 0.0;
    // If n - c < k, every k-subset includes at least one correct → 1.0.
    if (n - c < k) return 1.0;
    // Otherwise: 1 - C(n - c, k) / C(n, k).
    // Compute via iterative product to avoid huge factorial overflow:
    //   C(a, b) / C(n, k) = prod_{i=0}^{k-1} (n - c - i) / (n - i)
    double prod = 1.0;
    for (var i = 0; i < k; i++) {
      prod *= (n - c - i) / (n - i);
    }
    return 1.0 - prod;
  }

  /// Binomial coefficient "a choose b" = a! / (b! * (a - b)!).
  /// Overflow-safe iterative multiplication. Returns 0 when b < 0 or
  /// b > a. Used by tests to verify against the textbook formula.
  static int binomial(int a, int b) {
    if (b < 0 || b > a) return 0;
    if (b == 0 || b == a) return 1;
    // Symmetry: C(a, b) == C(a, a - b) — pick the smaller.
    if (b > a - b) b = a - b;
    var result = 1;
    for (var i = 0; i < b; i++) {
      result = result * (a - i) ~/ (i + 1);
    }
    return result;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PassAtK &&
          runtimeType == other.runtimeType &&
          n == other.n &&
          c == other.c &&
          k == other.k);

  @override
  int get hashCode => Object.hash(n, c, k);

  @override
  String toString() =>
      'PassAtK(n: $n, c: $c, k: $k, value: $value)';
}
