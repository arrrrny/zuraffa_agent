// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#2 (R2 - engine core loop).
//
// Concrete provider stub for the EngineLoop data layer. Mirrors the
// SteeringQueueProvider pattern (spec 033) and ToolResultProvider
// (spec 031): bodies throw UnimplementedError so the file is analyzable
// without forcing real I/O.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/engine_loop/engine_loop.dart';
import '../../../domain/services/engine_loop_service.dart';

class EngineLoopProvider
    with Loggable, FailureHandler
    implements EngineLoopService {
  EngineLoopProvider();

  @override
  Future<EngineLoop> current(NoParams params) async =>
      throw UnimplementedError('Implement EngineLoopProvider.current');

  @override
  Future<int> count(NoParams params) async =>
      throw UnimplementedError('Implement EngineLoopProvider.count');
}
