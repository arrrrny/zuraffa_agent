// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#7 (R6 - eval harness).
//
// Concrete provider for the PassKEmpirical data layer. Returns the active
// pass^k empirical snapshot. Replaces the previous UnimplementedError stub
// (spec 037).

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/pass_k_empirical/pass_k_empirical.dart';
import '../../../domain/services/pass_k_empirical_service.dart';

class PassKEmpiricalProvider
    with Loggable, FailureHandler
    implements PassKEmpiricalService {
  final PassKEmpirical _active;

  PassKEmpiricalProvider([PassKEmpirical? active])
      : _active = active ??
            const PassKEmpirical(
              id: 'default',
              taskId: 'mission-1',
              k: 10,
              successCount: 10,
              empiricalRate: 1.0,
            );

  @override
  Future<PassKEmpirical> current(NoParams params) async => _active;

  @override
  Future<int> count(NoParams params) async => 1;
}
