// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issues arrrrny/zuraffa_agent#27 and arrrrny/zuraffa_agent#28.
//
// Mock datasource for the StopPolicy value object. Mirrors the zfa-generated
// mock_datasource stub convention (see
// `lib/src/data/datasources/turn_record/turn_record_remote_datasource.dart`
// for the reference shape). Bodies throw UnimplementedError until a real
// store is wired by the consuming application.

import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/stop_policy/stop_policy.dart';
import 'stop_policy_datasource.dart';

class StopPolicyMockDatasource
    with Loggable, FailureHandler
    implements StopPolicyDatasource {
  StopPolicyMockDatasource();

  @override
  Future<StopPolicy> current() async =>
      throw UnimplementedError('Implement StopPolicyMockDatasource.current');

  @override
  Future<void> reset() async =>
      throw UnimplementedError('Implement StopPolicyMockDatasource.reset');
}
