// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/agent_tool/agent_tool.dart';
import '../../../domain/services/agent_tool_service.dart';

class AgentToolProvider
    with Loggable, FailureHandler
    implements AgentToolService {
  @override
  AgentTool getTool(String params) {
    final error = UnimplementedError('getTool not implemented');
    final stack = StackTrace.current;
    logAndHandleError(error, stack);
    throw error;
  }

  @override
  List<AgentTool> listTools() {
    final error = UnimplementedError('listTools not implemented');
    final stack = StackTrace.current;
    logAndHandleError(error, stack);
    throw error;
  }
}

// END GENERATED
