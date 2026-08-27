// Spec 27 — StopPolicy datasource pair tests (TDD cycle 2).
//
// Traces: tdd/test-list.md A3, U4..U7 (FR-002, FR-003, AC US2-1..2, edge-2).
// Supersedes the pre-refinement UnimplementedError stub assertions — the
// refined spec ships the in-memory persistence contract.

import 'package:test/test.dart';

import 'package:zuraffa_agent/src/data/datasources/stop_policy/stop_policy_datasource.dart';
import 'package:zuraffa_agent/src/data/datasources/stop_policy/stop_policy_mock_datasource.dart';
import 'package:zuraffa_agent/src/domain/entities/stop_policy/stop_policy.dart';

void main() {
  group('spec 027 — StopPolicy datasource pair', () {
    test('U4: StopPolicyMockDatasource is a StopPolicyDatasource', () {
      expect(StopPolicyMockDatasource(), isA<StopPolicyDatasource>());
    });

    test('U5: a fresh mock current() returns StopPolicy.defaultPolicy', () async {
      final ds = StopPolicyMockDatasource();
      expect(await ds.current(), equals(StopPolicy.defaultPolicy));
    });

    test('A3 + U6: update(policy) then current() returns exactly the policy written', () async {
      final ds = StopPolicyMockDatasource();
      const strict = StopPolicy(
        id: 'strict',
        maxTurns: 3,
        wallClockTimeout: Duration(seconds: 30),
        repetitionThreshold: 2,
        enabled: true,
      );
      final returned = await ds.update(strict);
      expect(returned, equals(strict));
      expect(await ds.current(), equals(strict));

      // edge-2: full replace — a changed id makes the old id unreachable.
      const relaxed = StopPolicy(
        id: 'relaxed',
        maxTurns: 50,
        wallClockTimeout: Duration.zero,
        repetitionThreshold: 5,
      );
      await ds.update(relaxed);
      expect(await ds.current(), equals(relaxed));
      expect(await ds.current(), isNot(equals(strict)));
    });

    test('U7: reset() on the mock restores the default', () async {
      final ds = StopPolicyMockDatasource();
      const strict = StopPolicy(
        id: 'strict',
        maxTurns: 3,
        wallClockTimeout: Duration(seconds: 30),
        repetitionThreshold: 2,
      );
      await ds.update(strict);
      await ds.reset();
      expect(await ds.current(), equals(StopPolicy.defaultPolicy));
    });
  });
}
