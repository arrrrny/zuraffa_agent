// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/agent_spec/agent_spec.dart';

abstract class AgentSpecDataSource with Loggable, FailureHandler {
  Future<AgentSpec> get(QueryParams<AgentSpec> params);
  Future<AgentSpec> update(UpdateParams<String, AgentSpecPatch> params);
}

// END GENERATED
