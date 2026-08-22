// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/agent_tool/agent_tool.dart';

abstract class AgentToolDataSource with Loggable, FailureHandler {
  Future<AgentTool> get(QueryParams<AgentTool> params);
  Future<AgentTool> update(UpdateParams<String, AgentToolPatch> params);
  Future<AgentTool> toggle(
    ToggleParams<String, Field<AgentTool, dynamic>> params,
  );
}

// END GENERATED
