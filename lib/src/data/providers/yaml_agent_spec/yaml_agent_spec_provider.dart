// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#6 (R5 - sub-agents & declarative).
//
// Concrete provider stub for the YamlAgentSpec data layer. Mirrors the
// SteeringQueueProvider pattern (spec 033) and ToolResultProvider
// (spec 031): bodies throw UnimplementedError so the file is analyzable
// without forcing real I/O.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/yaml_agent_spec/yaml_agent_spec.dart';
import '../../../domain/services/yaml_agent_spec_service.dart';

class YamlAgentSpecProvider
    with Loggable, FailureHandler
    implements YamlAgentSpecService {
  YamlAgentSpecProvider();

  @override
  Future<YamlAgentSpec> current(NoParams params) async =>
      throw UnimplementedError('Implement YamlAgentSpecProvider.current');

  @override
  Future<int> count(NoParams params) async =>
      throw UnimplementedError('Implement YamlAgentSpecProvider.count');
}
