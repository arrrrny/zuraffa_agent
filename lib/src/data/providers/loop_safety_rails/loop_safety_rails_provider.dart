// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#2 (R2 - engine core loop).
//
// Concrete provider for the LoopSafetyRails data layer. Returns the current
// safety-rails snapshot for the active mission. This replaces the previous
// throwing stub (spec 033 / issue #2 US4).

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/loop_safety_rails/loop_safety_rails.dart';
import '../../../domain/services/loop_safety_rails_service.dart';

class LoopSafetyRailsProvider
    with Loggable, FailureHandler
    implements LoopSafetyRailsService {
  final LoopSafetyRails _active;

  LoopSafetyRailsProvider([LoopSafetyRails? active])
      : _active = active ??
            const LoopSafetyRails(
              outcomeType: 'Idle',
              turnNumber: 0,
              reason: 'no-safety-rail-triggered',
              emittedAt: 0,
            );

  @override
  Future<LoopSafetyRails> current(NoParams params) async => _active;

  @override
  Future<int> count(NoParams params) async => 1;
}
