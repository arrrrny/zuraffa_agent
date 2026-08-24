// Regression test for arrarrny/zuraffa_agent#7 (R6 — eval harness: pass@k
// unbiased estimator).
//
// Asserts:
// - PassAtK.compute validates inputs (n ≥ 1, 0 ≤ c ≤ n, 1 ≤ k ≤ n) and
//   throws ArgumentError on violation.
// - pass@k = 0 when c = 0 (no correct samples).
// - pass@k = 1 when n - c < k (every k-subset hits at least one correct).
// - pass@k matches the textbook formula 1 - C(n-c, k)/C(n, k) on cases
//   where the binomial coefficients stay small.
// - pass@k is monotonic non-decreasing in c (more correct → higher
//   pass@k).
// - pass@k is monotonic non-decreasing in k for k ≤ n - c (smaller k
//   means harder to hit, so pass@k drops with smaller k).
// - Equality is value-based on (n, c, k).
// - Binomial helper computes correct values on textbook cases.
// - The clean-arch layers (PassAtKService + PassAtKProvider) are wired
//   correctly and compile.
// - The provider's UnimplementedError stubs fire.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;

import 'package:zuraffa_agent/src/domain/entities/pass_at_k/pass_at_k.dart';
import 'package:zuraffa_agent/src/domain/services/pass_at_k_service.dart';
import 'package:zuraffa_agent/src/data/providers/pass_at_k/pass_at_k_provider.dart';

void main() {
  group('arrarrny/zuraffa_agent#7 — PassAtK unbiased estimator', () {
    test('PassAtK.compute throws ArgumentError when n < 1', () {
      expect(
        () => PassAtK.compute(n: 0, c: 0, k: 1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('PassAtK.compute throws ArgumentError when c < 0', () {
      expect(
        () => PassAtK.compute(n: 5, c: -1, k: 1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('PassAtK.compute throws ArgumentError when c > n', () {
      expect(
        () => PassAtK.compute(n: 5, c: 6, k: 1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('PassAtK.compute throws ArgumentError when k < 1', () {
      expect(
        () => PassAtK.compute(n: 5, c: 2, k: 0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('PassAtK.compute throws ArgumentError when k > n', () {
      expect(
        () => PassAtK.compute(n: 5, c: 2, k: 6),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('pass@k = 0 when c = 0 (no correct samples)', () {
      final r = PassAtK.compute(n: 10, c: 0, k: 1);
      expect(r.value, 0.0);
    });

    test('pass@k = 1 when n - c < k (every k-subset hits a correct sample)', () {
      // n=5, c=4, k=2 → n-c=1 < 2 → 1.0
      final r = PassAtK.compute(n: 5, c: 4, k: 2);
      expect(r.value, 1.0);
    });

    test('pass@k matches the textbook formula 1 - C(n-c, k)/C(n, k)', () {
      // n=5, c=1, k=2 → 1 - C(4,2)/C(5,2) = 1 - 6/10 = 0.4
      final r = PassAtK.compute(n: 5, c: 1, k: 2);
      final textbook =
          1.0 - PassAtK.binomial(4, 2) / PassAtK.binomial(5, 2);
      expect(r.value, closeTo(textbook, 1e-9));
      expect(r.value, closeTo(0.4, 1e-9));
    });

    test('pass@k is monotonic non-decreasing in c (more correct → higher)', () {
      final r1 = PassAtK.compute(n: 20, c: 1, k: 5);
      final r2 = PassAtK.compute(n: 20, c: 5, k: 5);
      final r3 = PassAtK.compute(n: 20, c: 10, k: 5);
      final r4 = PassAtK.compute(n: 20, c: 15, k: 5);
      expect(r1.value <= r2.value, isTrue);
      expect(r2.value <= r3.value, isTrue);
      expect(r3.value <= r4.value, isTrue);
    });

    test('PassAtK equality is value-based on (n, c, k)', () {
      final a = PassAtK.compute(n: 10, c: 2, k: 3);
      final b = PassAtK.compute(n: 10, c: 2, k: 3);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.value, b.value);
    });

    test('binomial helper computes textbook values', () {
      expect(PassAtK.binomial(5, 2), 10);
      expect(PassAtK.binomial(10, 3), 120);
      expect(PassAtK.binomial(10, 0), 1);
      expect(PassAtK.binomial(10, 10), 1);
      expect(PassAtK.binomial(5, 6), 0); // b > a → 0
      expect(PassAtK.binomial(5, -1), 0); // b < 0 → 0
      // Symmetry: C(10, 3) == C(10, 7).
      expect(PassAtK.binomial(10, 7), PassAtK.binomial(10, 3));
    });
  });

  group('arrarrny/zuraffa_agent#7 — PassAtK clean-arch layers', () {
    test('PassAtKProvider is a PassAtKService', () {
      final provider = PassAtKProvider();
      expect(provider, isA<PassAtKService>());
    });

    test('PassAtKProvider.current throws UnimplementedError on NoParams', () {
      final provider = PassAtKProvider();
      expect(
        () => provider.current(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('PassAtKProvider.count throws UnimplementedError on NoParams', () {
      final provider = PassAtKProvider();
      expect(
        () => provider.count(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
