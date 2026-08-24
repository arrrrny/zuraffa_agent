// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#4 (R3 - tools & mcp).
//
// Concrete provider stub for the OversizedResultPolicy data layer. Mirrors the
// SteeringQueueProvider pattern (spec 033) and ToolResultProvider
// (spec 031): bodies throw UnimplementedError so the file is analyzable
// without forcing real I/O.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/oversized_result_policy/oversized_result_policy.dart';
import '../../../domain/services/oversized_result_policy_service.dart';

class OversizedResultPolicyProvider
    with Loggable, FailureHandler
    implements OversizedResultPolicyService {
  OversizedResultPolicyProvider();

  @override
  Future<OversizedResultPolicy> current(NoParams params) async =>
      throw UnimplementedError('Implement OversizedResultPolicyProvider.current');

  @override
  Future<int> count(NoParams params) async =>
      throw UnimplementedError('Implement OversizedResultPolicyProvider.count');
}
