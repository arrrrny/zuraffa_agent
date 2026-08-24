// Regression test for arrrrny/zuraffa_agent#13 + #27 + #28.
//
// Verifies:
// - (#27 + #28) the StopPolicyMockDatasource resolves cleanly (uri_does_not_exist
//   and implements_non_class are gone — closed by PR #45).
// - (#13) the StopPolicy entity supports the spec-exact surface including
//   Duration fields (maxTurns:int, wallClockTimeout:Duration,
//   repetitionThreshold:int, enabled:bool) — zfa v6.0.0 rejects Duration,
//   so the entity ships hand-curated. This test guards against any future
//   regression that drops the Duration field.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/stop_policy/stop_policy.dart';
import 'package:zuraffa_agent/src/data/datasources/stop_policy/stop_policy_datasource.dart';
import 'package:zuraffa_agent/src/data/datasources/stop_policy/stop_policy_mock_datasource.dart';

void main() {
  group('arrarrny/zuraffa_agent#27 + #28 — StopPolicy datasource pair', () {
    test('StopPolicyMockDatasource is a StopPolicyDatasource', () {
      expect(StopPolicyMockDatasource(), isA<StopPolicyDatasource>());
    });

    test('StopPolicyMockDatasource.current throws UnimplementedError', () {
      expect(
        () => StopPolicyMockDatasource().current(),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('StopPolicyMockDatasource.reset throws UnimplementedError', () {
      expect(
        () => StopPolicyMockDatasource().reset(),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });

  group('arrarrny/zuraffa_agent#13 — StopPolicy Duration field support', () {
    final policy = StopPolicy(
      id: 'default',
      maxTurns: 50,
      wallClockTimeout: Duration(minutes: 5),
      repetitionThreshold: 3,
      enabled: true,
    );

    test('StopPolicy carries a Duration wallClockTimeout field', () {
      expect(policy.wallClockTimeout, isA<Duration>());
      expect(policy.wallClockTimeout, Duration(minutes: 5));
    });

    test('StopPolicy carries int maxTurns + int repetitionThreshold', () {
      expect(policy.maxTurns, 50);
      expect(policy.repetitionThreshold, 3);
    });

    test('StopPolicy.enabled defaults to true', () {
      final inert = StopPolicy(
        id: 'inert',
        maxTurns: 0,
        wallClockTimeout: Duration.zero,
        repetitionThreshold: 0,
      );
      expect(inert.enabled, isTrue);
    });

    test('StopPolicy equality is value-based across all five fields', () {
      final a = StopPolicy(
        id: 'x',
        maxTurns: 1,
        wallClockTimeout: Duration(seconds: 1),
        repetitionThreshold: 1,
        enabled: true,
      );
      final b = StopPolicy(
        id: 'x',
        maxTurns: 1,
        wallClockTimeout: Duration(seconds: 1),
        repetitionThreshold: 1,
        enabled: true,
      );
      final c = StopPolicy(
        id: 'x',
        maxTurns: 1,
        wallClockTimeout: Duration(seconds: 1),
        repetitionThreshold: 1,
        enabled: false,
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('StopPolicy allows Duration.zero wall-clock (no time limit)', () {
      final noLimit = StopPolicy(
        id: 'no-limit',
        maxTurns: 100,
        wallClockTimeout: Duration.zero,
        repetitionThreshold: 5,
      );
      expect(noLimit.wallClockTimeout, Duration.zero);
    });
  });
}
