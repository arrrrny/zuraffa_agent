// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#3 (R1 - state & sessions).
//
// Concrete provider stub for the CompactionStrategy data layer. Mirrors the
// SteeringQueueProvider pattern (spec 033) and ToolResultProvider
// (spec 031): bodies throw UnimplementedError so the file is analyzable
// without forcing real I/O.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/compaction_strategy/compaction_strategy.dart';
import '../../../domain/services/compaction_strategy_service.dart';

class CompactionStrategyProvider
    with Loggable, FailureHandler
    implements CompactionStrategyService {
  CompactionStrategyProvider();

  @override
  Future<CompactionStrategy> current(NoParams params) async =>
      throw UnimplementedError('Implement CompactionStrategyProvider.current');

  @override
  Future<int> count(NoParams params) async =>
      throw UnimplementedError('Implement CompactionStrategyProvider.count');
}
