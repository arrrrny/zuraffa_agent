// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#7 (R6 - eval harness).
//
// Concrete provider for the GraderSealed data layer. Returns the active
// grader snapshot (exact/schema/model-judge). Replaces the previous
// UnimplementedError stub (spec 037).

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/grader_sealed/grader_sealed.dart';
import '../../../domain/services/grader_sealed_service.dart';

class GraderSealedProvider
    with Loggable, FailureHandler
    implements GraderSealedService {
  final GraderSealed _active;

  GraderSealedProvider([GraderSealed? active])
      : _active = active ??
            const GraderSealed(
              id: 'default',
              graderType: 'exact',
            );

  @override
  Future<GraderSealed> current(NoParams params) async => _active;

  @override
  Future<int> count(NoParams params) async => 1;
}
