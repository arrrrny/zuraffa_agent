// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#6 (R5 - sub-agents & declarative).
//
// Concrete provider stub for the SubAgentInstance data layer. Mirrors the
// SteeringQueueProvider pattern (spec 033) and ToolResultProvider
// (spec 031): bodies throw UnimplementedError so the file is analyzable
// without forcing real I/O.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/sub_agent_instance/sub_agent_instance.dart';
import '../../../domain/services/sub_agent_instance_service.dart';

class SubAgentInstanceProvider
    with Loggable, FailureHandler
    implements SubAgentInstanceService {
  SubAgentInstanceProvider();

  @override
  Future<SubAgentInstance> current(NoParams params) async =>
      throw UnimplementedError('Implement SubAgentInstanceProvider.current');

  @override
  Future<int> count(NoParams params) async =>
      throw UnimplementedError('Implement SubAgentInstanceProvider.count');
}
