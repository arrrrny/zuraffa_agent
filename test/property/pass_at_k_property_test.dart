// Property-based tests for the PassAtK value object — issue #128 AC-2.
//
// PassAtK.compute is a pure function of (n, c, k) — the textbook target for
// property tests. These properties encode the estimator's mathematical
// contract from Chen et al. 2021 (see the header of
// lib/src/domain/entities/pass_at_k/pass_at_k.dart):
//
//   M1  monotone non-decreasing in k   (more draws never lower pass@k)
//   M2  monotone non-decreasing in c   (more correct samples never lower it)
//   B1  bounded: 0.0 <= value <= 1.0
//   B2  exact boundaries: c == 0 -> 0.0; n - c < k -> 1.0
//   X1  cross-check against the textbook closed form 1 - C(n-c,k)/C(n,k)
//   X2  fromResults(outcomes, k) == compute(n, c, k) for any permutation
//   V1  validation rejects every invalid (n, c, k) triple
//   E1  equality/hashCode are functions of the input triple only
//   T1  meetsThreshold mirrors value >= threshold over random thresholds
//
// All randomness is seeded (see property_harness.dart) — CI-stable.
library;

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/pass_at_k/pass_at_k.dart';

import 'property_harness.dart';

const _eps = 1e-12;

void main() {
  group('PassAtK properties (seeded, randomized)', () {
    test('M1: pass@k is monotone non-decreasing in k for fixed (n, c)', () {
      check('M1 monotone in k', (rnd, trial) {
        final n = intBetween(rnd, 1, 40);
        if (n < 2) return; // monotonicity in k needs a k-1 >= 1 to compare
        final c = intBetween(rnd, 0, n);
        final k = intBetween(rnd, 2, n);
        final smaller = PassAtK.compute(n: n, c: c, k: k - 1).value;
        final larger = PassAtK.compute(n: n, c: c, k: k).value;
        expect(
          larger,
          greaterThanOrEqualTo(smaller - _eps),
          reason:
              'trial $trial: pass@$k ($larger) < pass@${k - 1} ($smaller) '
              'for n=$n c=$c',
        );
      }, iterations: 400);
    });

    test('M2: pass@k is monotone non-decreasing in c for fixed (n, k)', () {
      check('M2 monotone in c', (rnd, trial) {
        final n = intBetween(rnd, 1, 40);
        final k = intBetween(rnd, 1, n);
        final c = intBetween(rnd, 1, n);
        final fewer = PassAtK.compute(n: n, c: c - 1, k: k).value;
        final more = PassAtK.compute(n: n, c: c, k: k).value;
        expect(
          more,
          greaterThanOrEqualTo(fewer - _eps),
          reason:
              'trial $trial: pass@k with c=$c ($more) < with c=${c - 1} '
              '($fewer) for n=$n k=$k',
        );
      }, iterations: 400);
    });

    test('B1: value stays within [0, 1] over the whole random domain', () {
      check('B1 bounded', (rnd, trial) {
        final n = intBetween(rnd, 1, 60);
        final c = intBetween(rnd, 0, n);
        final k = intBetween(rnd, 1, n);
        final value = PassAtK.compute(n: n, c: c, k: k).value;
        expect(value, greaterThanOrEqualTo(0.0), reason: 'trial $trial');
        expect(value, lessThanOrEqualTo(1.0), reason: 'trial $trial');
      }, iterations: 400);
    });

    test('B2: exact boundaries — c=0 is 0.0, n-c<k is 1.0', () {
      check('B2 boundaries', (rnd, trial) {
        final n = intBetween(rnd, 1, 30);
        final k = intBetween(rnd, 1, n);
        expect(
          PassAtK.compute(n: n, c: 0, k: k).value,
          0.0,
          reason: 'trial $trial: no correct samples must be exactly 0',
        );
        // n - c < k: every k-subset contains a correct sample.
        final c = intBetween(rnd, n - k + 1, n);
        expect(
          PassAtK.compute(n: n, c: c, k: k).value,
          1.0,
          reason: 'trial $trial: n=$n c=$c k=$k must be exactly 1',
        );
      }, iterations: 300);
    });

    test('X1: matches the textbook closed form 1 - C(n-c,k)/C(n,k)', () {
      check('X1 closed form', (rnd, trial) {
        final n = intBetween(rnd, 1, 40);
        final c = intBetween(rnd, 0, n);
        final k = intBetween(rnd, 1, n);
        final computed = PassAtK.compute(n: n, c: c, k: k).value;
        if (c == 0) {
          expect(computed, 0.0);
          return;
        }
        if (n - c < k) {
          expect(computed, 1.0);
          return;
        }
        final closedForm =
            1.0 - PassAtK.binomial(n - c, k) / PassAtK.binomial(n, k);
        expect(
          computed,
          closeTo(closedForm, 1e-9),
          reason: 'trial $trial: n=$n c=$c k=$k',
        );
      }, iterations: 400);
    });

    test('X2: fromResults equals compute for any permutation of outcomes', () {
      check('X2 fromResults equivalence', (rnd, trial) {
        final n = intBetween(rnd, 1, 30);
        final c = intBetween(rnd, 0, n);
        final k = intBetween(rnd, 1, n);
        final outcomes = randomOutcomeList(rnd, n, c);
        final viaResults = PassAtK.fromResults(outcomes, k: k).value;
        final viaTriple = PassAtK.compute(n: n, c: c, k: k).value;
        expect(
          viaResults,
          viaTriple,
          reason: 'trial $trial: permutation must not change the estimator',
        );
      }, iterations: 300);
    });

    test('V1: invalid (n, c, k) triples always throw ArgumentError', () {
      check('V1 validation', (rnd, trial) {
        final n = intBetween(rnd, 1, 20);
        // One violation per trial, chosen at random.
        switch (rnd.nextInt(5)) {
          case 0:
            expect(
              () => PassAtK.compute(n: 0, c: 0, k: 1),
              throwsArgumentError,
            );
          case 1:
            expect(
              () => PassAtK.compute(n: n, c: -1, k: 1),
              throwsArgumentError,
            );
          case 2:
            expect(
              () => PassAtK.compute(n: n, c: n + 1, k: 1),
              throwsArgumentError,
            );
          case 3:
            expect(
              () => PassAtK.compute(n: n, c: 0, k: 0),
              throwsArgumentError,
            );
          default:
            expect(
              () => PassAtK.compute(n: n, c: 0, k: n + 1),
              throwsArgumentError,
            );
        }
      }, iterations: 200);
    });

    test('E1: equality/hashCode depend only on the (n, c, k) triple', () {
      check('E1 value semantics', (rnd, trial) {
        final n = intBetween(rnd, 1, 30);
        final c = intBetween(rnd, 0, n);
        final k = intBetween(rnd, 1, n);
        final a = PassAtK.compute(n: n, c: c, k: k);
        final b = PassAtK.compute(n: n, c: c, k: k);
        expect(a, equals(b), reason: 'trial $trial');
        expect(a.hashCode, b.hashCode, reason: 'trial $trial');
        // The estimator is derived from the triple — same triple, same
        // value; and value equality cannot outrun triple equality.
        final differentK = PassAtK.compute(n: n, c: c, k: k == n ? 1 : k + 1);
        if (differentK.k != k) {
          expect(
            a,
            isNot(equals(differentK)),
            reason: 'trial $trial: different k must not be equal',
          );
        }
      }, iterations: 200);
    });

    test('T1: meetsThreshold is exactly `value >= threshold`', () {
      check('T1 threshold gate', (rnd, trial) {
        final n = intBetween(rnd, 1, 25);
        final c = intBetween(rnd, 0, n);
        final k = intBetween(rnd, 1, n);
        final passAtK = PassAtK.compute(n: n, c: c, k: k);
        final threshold = rnd.nextInt(11) / 10;
        expect(
          passAtK.meetsThreshold(threshold),
          passAtK.value >= threshold,
          reason: 'trial $trial: value=${passAtK.value} t=$threshold',
        );
        // Out-of-range gates are policy bugs, not near-misses.
        if (trial.isEven) {
          expect(() => passAtK.meetsThreshold(-0.1), throwsArgumentError);
          expect(() => passAtK.meetsThreshold(1.1), throwsArgumentError);
        }
      }, iterations: 200);
    });

    test('X3: binomial obeys its contract (0 out of range, 1 at edges)', () {
      // Mutation rubric PAK-3: the out-of-range branch of binomial was
      // never pinned (X1 only calls it in-range) — a `return 0` -> `return 1`
      // mutant survived. This pins the whole contract.
      check('X3 binomial contract', (rnd, trial) {
        final a = intBetween(rnd, 0, 30);
        // Out of range: C(a, b) == 0 for b < 0 or b > a.
        expect(
          PassAtK.binomial(a, -1 - rnd.nextInt(3)),
          0,
          reason: 'trial $trial',
        );
        expect(
          PassAtK.binomial(a, a + 1 + rnd.nextInt(3)),
          0,
          reason: 'trial $trial',
        );
        // Edges: C(a, 0) == C(a, a) == 1.
        expect(PassAtK.binomial(a, 0), 1, reason: 'trial $trial');
        expect(PassAtK.binomial(a, a), 1, reason: 'trial $trial');
        // Symmetry: C(a, b) == C(a, a - b).
        final b = intBetween(rnd, 0, a);
        expect(
          PassAtK.binomial(a, b),
          PassAtK.binomial(a, a - b),
          reason: 'trial $trial',
        );
        // Textbook identity: C(a, b) == C(a-1, b-1) + C(a-1, b) for 0<b<a.
        if (b > 0 && b < a) {
          expect(
            PassAtK.binomial(a, b),
            PassAtK.binomial(a - 1, b - 1) + PassAtK.binomial(a - 1, b),
            reason: 'trial $trial: Pascal recurrence violated',
          );
        }
      }, iterations: 300);
    });

    test('sanity: seeded harness explores a wide domain (smoke)', () {
      // Guards the harness itself against degenerate generator drift: with
      // the committed seed the loop must exercise small AND large n.
      final seen = <int>{};
      check('harness domain smoke', (rnd, trial) {
        seen.add(intBetween(rnd, 1, 60));
      }, iterations: 200);
      expect(seen.length, greaterThan(40));
      expect(seen, contains(1));
      expect(seen.any((n) => n > 50), isTrue, reason: 'large n exercised');
    });
  });
}
