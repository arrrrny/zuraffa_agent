// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#2 (R2 - engine core loop).
//
// Concrete provider stub for the LoopSafetyRails data layer. Mirrors the
// SteeringQueueProvider pattern (spec 033) and ToolResultProvider
// (spec 031): bodies throw UnimplementedError so the file is analyzable
// without forcing real I/O.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/loop_safety_rails/loop_safety_rails.dart';
import '../../../domain/services/loop_safety_rails_service.dart';

class LoopSafetyRailsProvider
    with Loggable, FailureHandler
    implements LoopSafetyRailsService {
  LoopSafetyRailsProvider();

  @override
  Future<LoopSafetyRails> current(NoParams params) async =>
      throw UnimplementedError('Implement LoopSafetyRailsProvider.current');

  @override
  Future<int> count(NoParams params) async =>
      throw UnimplementedError('Implement LoopSafetyRailsProvider.count');
}
