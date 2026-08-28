// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#6 (R5 - sub-agents & declarative).
//
// Concrete provider for the YamlAgentSpec data layer. Returns the active
// declarative agent spec snapshot as a constructed default (spec 052).

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/yaml_agent_spec/yaml_agent_spec.dart';
import '../../../domain/services/yaml_agent_spec_service.dart';

class YamlAgentSpecProvider
    with Loggable, FailureHandler
    implements YamlAgentSpecService {
  final YamlAgentSpec _active;

  YamlAgentSpecProvider([YamlAgentSpec? active])
      : _active = active ??
            const YamlAgentSpec(
              id: 'default',
              name: 'base',
              toolAllowlist: ['read_file', 'list_dir'],
              systemPrompt: 'You are a helpful agent operating inside zuraffa.',
            );

  @override
  Future<YamlAgentSpec> current(NoParams params) async => _active;

  @override
  Future<int> count(NoParams params) async => 1;
}
