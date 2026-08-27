// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#14 (zfa clean-arch layers never emit).
//
// Concrete repository for the StopPolicy value object, implementing the
// domain-layer StopPolicyRepository by delegating to a StopPolicyDatasource
// (specs/27-stop_policy-datasource-pair). This is the seam that lets a
// Hive- or remote-backed datasource replace the mock without touching the
// provider, the service surface, or the engine loop.
//
// StopPolicy is a single-instance value object, so the repository keeps the
// domain's id-keyed surface but backs it with a single policy slot: reads
// verify the stored policy's id and raise StateError on mismatch — a
// wrong-id read is a wiring bug and must never be silently substituted.

import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/stop_policy/stop_policy.dart';
import '../../../domain/repositories/stop_policy_repository.dart';
import '../datasources/stop_policy/stop_policy_datasource.dart';

/// Data-layer implementation of [StopPolicyRepository] over any
/// [StopPolicyDatasource].
class StopPolicyRepositoryImpl with Loggable, FailureHandler
    implements StopPolicyRepository {
  StopPolicyRepositoryImpl(this._datasource);

  final StopPolicyDatasource _datasource;

  @override
  Future<StopPolicy> getCurrent(String id) async {
    final policy = await _datasource.current();
    if (policy.id != id) {
      throw StateError(
        'No StopPolicy stored for id "$id" (stored: "${policy.id}"). '
        'Wrong-id reads are wiring bugs — update() fully replaces the stored '
        'policy, so a changed id makes the old id unreachable.',
      );
    }
    return policy;
  }

  @override
  Future<StopPolicy> update(StopPolicy policy) => _datasource.update(policy);

  @override
  Future<void> reset(String id) => _datasource.reset();
}
