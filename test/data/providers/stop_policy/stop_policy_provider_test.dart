// Spec 27 — StopPolicyProvider chain-consumption tests (TDD cycle 4).
//
// Traces: tdd/test-list.md A1, A2, A4, A5, U10..U12 (FR-005, FR-006,
// AC US1-1..2, US2-2, US3-1, SC-003).
// Supersedes the pre-refinement UnimplementedError stub assertions — the
// provider now consumes the datasource for real.
//
// Design note (TDD cycle 4 red): the service surface is id-less (NoParams),
// so the provider binds to the datasource's id-less current(); the
// id-keyed repository seam is covered by its own test file.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;

import 'package:zuraffa_agent/src/data/datasources/stop_policy/stop_policy_datasource.dart';
import 'package:zuraffa_agent/src/data/datasources/stop_policy/stop_policy_mock_datasource.dart';
import 'package:zuraffa_agent/src/data/providers/stop_policy/stop_policy_provider.dart';
import 'package:zuraffa_agent/src/domain/entities/stop_policy/stop_policy.dart';
import 'package:zuraffa_agent/src/domain/services/stop_policy_service.dart';

void main() {
  group('spec 027 — StopPolicyProvider consumes the chain (A1..A5, U10..U12)', () {
    test('U10: StopPolicyProvider is a StopPolicyService', () {
      expect(StopPolicyProvider(), isA<StopPolicyService>());
    });

    test('U11: parameterless StopPolicyProvider() keeps compiling (default wiring)', () {
      final provider = StopPolicyProvider();
      expect(provider, isNotNull);
    });

    test('A1: a fresh chain returns the default policy from current()', () async {
      final provider = StopPolicyProvider();
      expect(await provider.current(NoParams()), equals(StopPolicy.defaultPolicy));
    });

    test('A2 + A5: a policy seeded into the datasource is served by current(NoParams())', () async {
      final ds = StopPolicyMockDatasource();
      const strict = StopPolicy(
        id: 'strict',
        maxTurns: 3,
        wallClockTimeout: Duration(seconds: 30),
        repetitionThreshold: 2,
      );
      await ds.update(strict);

      final provider = StopPolicyProvider(datasource: ds);
      expect(await provider.current(NoParams()), equals(strict));
    });

    test('A4: reset() restores the documented default through the whole chain', () async {
      final ds = StopPolicyMockDatasource();
      final provider = StopPolicyProvider(datasource: ds);

      const strict = StopPolicy(
        id: 'strict',
        maxTurns: 3,
        wallClockTimeout: Duration(seconds: 30),
        repetitionThreshold: 2,
      );
      await ds.update(strict);
      expect(await provider.current(NoParams()), equals(strict));

      await ds.reset();
      expect(await provider.current(NoParams()), equals(StopPolicy.defaultPolicy));
    });

    test('U12: defaultPolicy(NoParams) returns the canonical constant', () {
      final provider = StopPolicyProvider();
      expect(provider.defaultPolicy(NoParams()), equals(StopPolicy.defaultPolicy));
    });

    test('A5: the provider serves reads through the datasource seam', () async {
      final ds = StopPolicyMockDatasource();
      final provider = StopPolicyProvider(datasource: ds);

      // Write through the datasource (the seam), read through the provider.
      const relaxed = StopPolicy(
        id: 'relaxed',
        maxTurns: 50,
        wallClockTimeout: Duration.zero,
        repetitionThreshold: 5,
      );
      await ds.update(relaxed);
      expect(await provider.current(NoParams()), equals(relaxed));
      expect(ds, isA<StopPolicyDatasource>());
    });
  });
}
