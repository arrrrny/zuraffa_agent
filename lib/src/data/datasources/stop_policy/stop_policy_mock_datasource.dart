// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issues arrrrny/zuraffa_agent#27 and arrrrny/zuraffa_agent#28.
//
// Mock datasource for the StopPolicy value object — the in-memory reference
// implementation of the StopPolicyDatasource persistence contract
// (specs/27-stop_policy-datasource-pair). Seeded with
// StopPolicy.defaultPolicy; update fully replaces; reset restores the
// default.

import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/stop_policy/stop_policy.dart';
import 'stop_policy_datasource.dart';

/// In-memory [StopPolicyDatasource].
///
/// Holds a single policy slot (the value object has no identity-based CRUD
/// surface). Suitable as the reference implementation for tests and as the
/// wiring target until a Hive- or remote-backed datasource exists.
class StopPolicyMockDatasource
    with Loggable, FailureHandler
    implements StopPolicyDatasource {
  StopPolicyMockDatasource({StopPolicy? initial})
      : _policy = initial ?? StopPolicy.defaultPolicy;

  StopPolicy _policy;

  @override
  Future<StopPolicy> current() async => _policy;

  @override
  Future<StopPolicy> update(StopPolicy policy) async {
    _policy = policy;
    return _policy;
  }

  @override
  Future<void> reset() async {
    _policy = StopPolicy.defaultPolicy;
  }
}
