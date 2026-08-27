// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#14.
//
// Concrete provider for the StopPolicy data layer, implementing the domain
// StopPolicyService by consuming a StopPolicyDatasource
// (specs/27-stop_policy-datasource-pair).
//
// Replaces the UnimplementedError stubs from the pre-refinement scaffold:
// current(NoParams) serves the live policy through the datasource's id-less
// read; defaultPolicy(NoParams) returns the canonical StopPolicy.defaultPolicy.
// The service surface is id-less by design (NoParams), so the provider binds
// to the datasource contract rather than the id-keyed repository — the
// repository remains the id-keyed domain-facing seam over the same datasource.
//
// The parameterless constructor keeps the historical wiring compiling by
// defaulting to a fresh mock datasource behind the interface.

import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/stop_policy/stop_policy.dart';
import '../../../domain/services/stop_policy_service.dart';
import '../../datasources/stop_policy/stop_policy_datasource.dart';
import '../../datasources/stop_policy/stop_policy_mock_datasource.dart';

/// Data-layer implementation of [StopPolicyService].
///
/// The engine-facing surface of the stop-policy chain:
/// provider -> datasource (id-less live read). Construct with a custom
/// [datasource] to swap the backend; construct parameterless for the
/// default in-memory wiring.
class StopPolicyProvider with Loggable, FailureHandler
    implements StopPolicyService {
  StopPolicyProvider({StopPolicyDatasource? datasource})
      : _datasource = datasource ?? StopPolicyMockDatasource();

  final StopPolicyDatasource _datasource;

  @override
  Future<StopPolicy> current(NoParams params) => _datasource.current();

  @override
  StopPolicy defaultPolicy(NoParams params) => StopPolicy.defaultPolicy;
}
