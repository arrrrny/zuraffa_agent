// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#4 (R3 - tools & mcp).
//
// Concrete provider for the ToolDispatchMode data layer. Returns the active
// dispatch policy. Replaces the previous UnimplementedError stub (spec 048).

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/tool_dispatch_mode/tool_dispatch_mode.dart';
import '../../../domain/services/tool_dispatch_mode_service.dart';

class ToolDispatchModeProvider
    with Loggable, FailureHandler
    implements ToolDispatchModeService {
  final ToolDispatchMode _active;

  ToolDispatchModeProvider([ToolDispatchMode? active])
      : _active = active ??
            const ToolDispatchMode(
              id: 'default',
              mode: 'sequential',
              maxParallel: 1,
              failFast: true,
            );

  @override
  Future<ToolDispatchMode> current(NoParams params) async => _active;

  @override
  Future<int> count(NoParams params) async => 1;
}
