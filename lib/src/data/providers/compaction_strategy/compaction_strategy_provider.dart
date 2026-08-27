// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#3 (R1 - state & sessions).
//
// Concrete provider for the CompactionStrategy data layer. Returns the active
// compaction strategy (selective retain/summarize). Replaces the previous
// UnimplementedError stub (spec 033).

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/compaction_strategy/compaction_strategy.dart';
import '../../../domain/services/compaction_strategy_service.dart';

class CompactionStrategyProvider
    with Loggable, FailureHandler
    implements CompactionStrategyService {
  final CompactionStrategy _active;

  CompactionStrategyProvider([CompactionStrategy? active])
      : _active = active ??
            const CompactionStrategy(
              id: 'selective',
              sessionId: '',
              retainEntryIds: [],
              summarizeEntryIds: [],
              artifactRefs: [],
              compactedAt: 0,
            );

  @override
  Future<CompactionStrategy> current(NoParams params) async => _active;

  @override
  Future<int> count(NoParams params) async => 1;
}
