// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#4 (R3 - tools & mcp).
//
// Concrete provider for the OversizedResultPolicy data layer. Returns the
// active oversized-result policy (summarize + artifactRef). Replaces the
// previous UnimplementedError stub (spec 031).

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/oversized_result_policy/oversized_result_policy.dart';
import '../../../domain/services/oversized_result_policy_service.dart';

class OversizedResultPolicyProvider
    with Loggable, FailureHandler
    implements OversizedResultPolicyService {
  final OversizedResultPolicy _active;

  OversizedResultPolicyProvider([OversizedResultPolicy? active])
      : _active = active ??
            const OversizedResultPolicy(
              id: 'default',
              thresholdBytes: 65536,
              summaryMaxChars: 2000,
              artifactStore: './artifacts',
            );

  @override
  Future<OversizedResultPolicy> current(NoParams params) async => _active;

  @override
  Future<int> count(NoParams params) async => 1;
}
