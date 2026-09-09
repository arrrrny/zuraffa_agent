// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#6 (R5 - sub-agents & declarative).
//
// Concrete provider for the YamlAgentSpec data layer. Returns the active
// declarative agent spec snapshot (spec 052).
//
// spec 106 (issue #117): fail closed — there is NO default agent spec. An
// explicit spec must be injected; absence is a construction-time error.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/yaml_agent_spec/yaml_agent_spec.dart';
import '../../../domain/services/yaml_agent_spec_service.dart';

class YamlAgentSpecProvider
    with Loggable, FailureHandler
    implements YamlAgentSpecService {
  final YamlAgentSpec _active;

  YamlAgentSpecProvider([YamlAgentSpec? active]) : _active = _require(active);

  static YamlAgentSpec _require(YamlAgentSpec? active) {
    if (active == null) {
      throw ArgumentError.value(
        active,
        'spec',
        'YamlAgentSpecProvider requires an injected YamlAgentSpec — '
        'no default is provided (issue #117)',
      );
    }
    return active;
  }

  @override
  Future<YamlAgentSpec> current(NoParams params) async => _active;

  @override
  Future<int> count(NoParams params) async => 1;
}
