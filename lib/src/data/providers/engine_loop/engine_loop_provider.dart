// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#2 (R2 - engine core loop).
//
// Concrete provider for the EngineLoop data layer. Returns the active loop
// configuration (turn cap, wall-clock budget, repetition threshold). Replaces
// the previous UnimplementedError stub (spec 045).

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/engine_loop/engine_loop.dart';
import '../../../domain/services/engine_loop_service.dart';

class EngineLoopProvider
    with Loggable, FailureHandler
    implements EngineLoopService {
  final EngineLoop _active;

  EngineLoopProvider([EngineLoop? active])
      : _active = active ??
            const EngineLoop(
              id: 'default',
              sessionId: '',
              maxTurns: 50,
              wallClockTimeoutMs: 600000,
              repetitionThreshold: 3,
            );

  @override
  Future<EngineLoop> current(NoParams params) async => _active;

  @override
  Future<int> count(NoParams params) async => 1;
}
