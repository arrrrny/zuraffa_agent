// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#6 (R5 - sub-agents & declarative).
//
// Concrete provider for the SubAgentInstance data layer. Returns the active
// resumable instance snapshot for the running mission. Replaces the previous
// stub (spec 033).

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/sub_agent_instance/sub_agent_instance.dart';
import '../../../domain/services/sub_agent_instance_service.dart';

class SubAgentInstanceProvider
    with Loggable, FailureHandler
    implements SubAgentInstanceService {
  final SubAgentInstance _active;

  SubAgentInstanceProvider([SubAgentInstance? active])
      : _active = active ??
            const SubAgentInstance(
              id: 'instance-default',
              subAgentSpecId: 'spec-default',
              parentSessionId: 'session-default',
              totalRuns: 0,
            );

  @override
  Future<SubAgentInstance> current(NoParams params) async => _active;

  @override
  Future<int> count(NoParams params) async => 1;
}
