// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#14.
//
// Concrete provider stub for the StopPolicy data layer. Mirrors the
// ArtifactProvider pattern from PR #32: bodies throw UnimplementedError so
// the file is analyzable without forcing real I/O. The parameterless
// methods (current, defaultPolicy) declare NoParams params so the @override
// clause matches the StopPolicyService interface exactly.

import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/stop_policy/stop_policy.dart';
import '../../../domain/services/stop_policy_service.dart';

class StopPolicyProvider with Loggable, FailureHandler implements StopPolicyService {
  StopPolicyProvider();

  @override
  Future<StopPolicy> current(NoParams params) async =>
      throw UnimplementedError('Implement StopPolicyProvider.current');

  @override
  StopPolicy defaultPolicy(NoParams params) =>
      throw UnimplementedError('Implement StopPolicyProvider.defaultPolicy');
}
