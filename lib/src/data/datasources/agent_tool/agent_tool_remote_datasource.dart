// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/agent_tool/agent_tool.dart';
import 'agent_tool_datasource.dart';

class AgentToolRemoteDataSource
    with Loggable, FailureHandler
    implements AgentToolDataSource {
  @override
  Future<AgentTool> get(QueryParams<AgentTool> params) async {
    throw UnimplementedError('Implement remote get');
  }

  @override
  Future<AgentTool> update(UpdateParams<String, AgentToolPatch> params) async {
    throw UnimplementedError('Implement remote update');
  }

  @override
  Future<AgentTool> toggle(
    ToggleParams<String, Field<AgentTool, dynamic>> params,
  ) async {
    throw UnimplementedError('Implement remote toggle');
  }
}

// END GENERATED
