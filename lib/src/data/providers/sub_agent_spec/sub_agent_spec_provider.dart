// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#6 (R5 — sub-agents & specs).
//
// Concrete provider for the SubAgentSpec data layer. Returns the current
// (most-recently-registered) declarative spec for the running mission.
// Replaces the previous stub (spec 033).

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/sub_agent_spec/sub_agent_spec.dart';
import '../../../domain/services/sub_agent_spec_service.dart';

class SubAgentSpecProvider
    with Loggable, FailureHandler
    implements SubAgentSpecService {
  final SubAgentSpec _active;

  SubAgentSpecProvider([SubAgentSpec? active])
      : _active = active ??
            SubAgentSpec(
              name: 'explore',
              description: 'Default exploratory sub-agent.',
              systemPrompt: 'You are an explorer.',
            );

  @override
  Future<SubAgentSpec> current(NoParams params) async => _active;

  @override
  Future<int> count(NoParams params) async => 1;
}
