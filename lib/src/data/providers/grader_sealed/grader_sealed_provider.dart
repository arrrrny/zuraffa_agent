// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#7 (R6 - eval harness).
//
// Concrete provider stub for the GraderSealed data layer. Mirrors the
// SteeringQueueProvider pattern (spec 033) and ToolResultProvider
// (spec 031): bodies throw UnimplementedError so the file is analyzable
// without forcing real I/O.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/grader_sealed/grader_sealed.dart';
import '../../../domain/services/grader_sealed_service.dart';

class GraderSealedProvider
    with Loggable, FailureHandler
    implements GraderSealedService {
  GraderSealedProvider();

  @override
  Future<GraderSealed> current(NoParams params) async =>
      throw UnimplementedError('Implement GraderSealedProvider.current');

  @override
  Future<int> count(NoParams params) async =>
      throw UnimplementedError('Implement GraderSealedProvider.count');
}
