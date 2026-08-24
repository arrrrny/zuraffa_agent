// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#6 (R5 - sub-agents & declarative).
//
// Concrete provider stub for the DispatchTool data layer. Mirrors the
// SteeringQueueProvider pattern (spec 033) and ToolResultProvider
// (spec 031): bodies throw UnimplementedError so the file is analyzable
// without forcing real I/O.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/dispatch_tool/dispatch_tool.dart';
import '../../../domain/services/dispatch_tool_service.dart';

class DispatchToolProvider
    with Loggable, FailureHandler
    implements DispatchToolService {
  DispatchToolProvider();

  @override
  Future<DispatchTool> current(NoParams params) async =>
      throw UnimplementedError('Implement DispatchToolProvider.current');

  @override
  Future<int> count(NoParams params) async =>
      throw UnimplementedError('Implement DispatchToolProvider.count');
}
