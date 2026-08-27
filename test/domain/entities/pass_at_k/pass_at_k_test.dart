// Spec 037 (issue arrrrny/zuraffa_agent#7, R6) — PassAtK eval-run sampling
// and threshold semantics, test-first via /speckit.tdd.run.
//
// Behaviors (specs/037-pass-at-k/tdd/test-list.md):
// - U1/U2 (FR-001): fromResults over an eval run (sampling without
//   replacement, n=length, c=trueCount) + its input errors.
// - U3/U4 (FR-002): meetsThreshold inclusive boundary + range/NaN errors.
// - U5 (FR-003): k-sweep monotonicity characterization pin.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/pass_at_k/pass_at_k.dart';

void main() {
  group('spec 037 — PassAtK.fromResults (FR-001)', () {
    test('U1: fromResults derives n/c and equals compute on the triple', () {
      final outcomes = [
        true, false, true, true, false,
        true, false, true, false, false, // 6 true, 4 false
      ];
      final viaRun = PassAtK.fromResults(outcomes, k: 3);
      final direct = PassAtK.compute(n: 10, c: 6, k: 3);
      expect(viaRun.n, 10);
      expect(viaRun.c, 6);
      expect(viaRun.k, 3);
      expect(viaRun.value, closeTo(direct.value, 1e-12));
      expect(viaRun, equals(direct));
    });

    test('U2: empty outcomes throws ArgumentError', () {
      expect(
        () => PassAtK.fromResults(const [], k: 1),
        throwsA(
          isA<ArgumentError>()
              .having((e) => e.name, 'name', contains('outcomes')),
        ),
      );
    });

    test('U2: k=0 and k=n+1 throw ArgumentError', () {
      final outcomes = [true, false, true];
      expect(
        () => PassAtK.fromResults(outcomes, k: 0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => PassAtK.fromResults(outcomes, k: 4),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('U2: outcome order does not matter (count-only sampling)', () {
      final sorted = [true, true, true, false, false, false, false];
      final shuffled = [false, true, false, true, false, false, true];
      expect(
        PassAtK.fromResults(sorted, k: 2).value,
        closeTo(PassAtK.fromResults(shuffled, k: 2).value, 1e-12),
      );
    });
  });
}
