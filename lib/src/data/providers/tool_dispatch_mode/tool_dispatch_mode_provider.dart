// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#4 (R3 - tools & mcp).
//
// Concrete provider stub for the ToolDispatchMode data layer. Mirrors the
// SteeringQueueProvider pattern (spec 033) and ToolResultProvider
// (spec 031): bodies throw UnimplementedError so the file is analyzable
// without forcing real I/O.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/tool_dispatch_mode/tool_dispatch_mode.dart';
import '../../../domain/services/tool_dispatch_mode_service.dart';

class ToolDispatchModeProvider
    with Loggable, FailureHandler
    implements ToolDispatchModeService {
  ToolDispatchModeProvider();

  @override
  Future<ToolDispatchMode> current(NoParams params) async =>
      throw UnimplementedError('Implement ToolDispatchModeProvider.current');

  @override
  Future<int> count(NoParams params) async =>
      throw UnimplementedError('Implement ToolDispatchModeProvider.count');
}
