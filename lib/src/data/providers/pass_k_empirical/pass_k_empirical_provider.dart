// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#7 (R6 - eval harness).
//
// Concrete provider stub for the PassKEmpirical data layer. Mirrors the
// SteeringQueueProvider pattern (spec 033) and ToolResultProvider
// (spec 031): bodies throw UnimplementedError so the file is analyzable
// without forcing real I/O.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/pass_k_empirical/pass_k_empirical.dart';
import '../../../domain/services/pass_k_empirical_service.dart';

class PassKEmpiricalProvider
    with Loggable, FailureHandler
    implements PassKEmpiricalService {
  PassKEmpiricalProvider();

  @override
  Future<PassKEmpirical> current(NoParams params) async =>
      throw UnimplementedError('Implement PassKEmpiricalProvider.current');

  @override
  Future<int> count(NoParams params) async =>
      throw UnimplementedError('Implement PassKEmpiricalProvider.count');
}
