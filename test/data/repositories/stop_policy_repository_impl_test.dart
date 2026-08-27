// Spec 27 — StopPolicyRepositoryImpl tests (TDD cycle 3).
//
// Traces: tdd/test-list.md A6, U8..U9 (FR-004, AC US3-2, edge-1/2, SC-004).
// The repository is the seam between the domain layer and the datasource:
// delegation for reads/writes, typed StateError on id mismatch.

import 'package:test/test.dart';

import 'package:zuraffa_agent/src/data/datasources/stop_policy/stop_policy_mock_datasource.dart';
import 'package:zuraffa_agent/src/data/repositories/stop_policy_repository_impl.dart';
import 'package:zuraffa_agent/src/domain/entities/stop_policy/stop_policy.dart';
import 'package:zuraffa_agent/src/domain/repositories/stop_policy_repository.dart';

void main() {
  group('spec 027 — StopPolicyRepositoryImpl (A6, U8..U9)', () {
    test('U8: StopPolicyRepositoryImpl is a StopPolicyRepository', () {
      expect(
        StopPolicyRepositoryImpl(StopPolicyMockDatasource()),
        isA<StopPolicyRepository>(),
      );
    });

    test('U9: getCurrent delegates to the datasource for the matching id', () async {
      final ds = StopPolicyMockDatasource();
      const strict = StopPolicy(
        id: 'strict',
        maxTurns: 3,
        wallClockTimeout: Duration(seconds: 30),
        repetitionThreshold: 2,
      );
      await ds.update(strict);

      final repo = StopPolicyRepositoryImpl(ds);
      expect(await repo.getCurrent('strict'), equals(strict));
      expect(await repo.getCurrent('default'), isNot(equals(strict)));
    });

    test('A6: getCurrent with an unknown id raises StateError', () async {
      final repo = StopPolicyRepositoryImpl(StopPolicyMockDatasource());
      await expectLater(
        repo.getCurrent('no-such-policy'),
        throwsA(isA<StateError>()),
      );
    });

    test('U9: update delegates (write through to the datasource)', () async {
      final ds = StopPolicyMockDatasource();
      final repo = StopPolicyRepositoryImpl(ds);
      const relaxed = StopPolicy(
        id: 'relaxed',
        maxTurns: 50,
        wallClockTimeout: Duration.zero,
        repetitionThreshold: 5,
      );
      await repo.update(relaxed);
      expect(await ds.current(), equals(relaxed));
      expect(await repo.getCurrent('relaxed'), equals(relaxed));
    });

    test('U9: reset delegates (restores the default through the repository)', () async {
      final ds = StopPolicyMockDatasource();
      final repo = StopPolicyRepositoryImpl(ds);
      const strict = StopPolicy(
        id: 'strict',
        maxTurns: 3,
        wallClockTimeout: Duration(seconds: 30),
        repetitionThreshold: 2,
      );
      await repo.update(strict);
      await repo.reset('strict');
      expect(await repo.getCurrent('default'), equals(StopPolicy.defaultPolicy));
    });

    test('edge-2: id-mismatched update makes the old id unreachable', () async {
      final ds = StopPolicyMockDatasource();
      final repo = StopPolicyRepositoryImpl(ds);
      await repo.update(const StopPolicy(
        id: 'old',
        maxTurns: 10,
        wallClockTimeout: Duration.zero,
        repetitionThreshold: 5,
      ));
      await repo.update(const StopPolicy(
        id: 'new',
        maxTurns: 20,
        wallClockTimeout: Duration.zero,
        repetitionThreshold: 5,
      ));
      await expectLater(repo.getCurrent('old'), throwsA(isA<StateError>()));
    });
  });
}
