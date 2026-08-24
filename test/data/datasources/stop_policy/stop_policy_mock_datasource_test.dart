// Regression test for arrrrny/zuraffa_agent#27 + #28.
//
// Verifies the StopPolicyMockDatasource resolves cleanly:
// - import resolves (uri_does_not_exist is gone)
// - implements clause resolves (implements_non_class is gone)
// - mock bodies throw UnimplementedError as designed

import 'package:test/test.dart';
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
}
