// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/agent_spec/agent_spec.dart';
import '../../../domain/services/agent_spec_service.dart';

class AgentSpecProvider
    with Loggable, FailureHandler
    implements AgentSpecService {
  @override
  AgentSpec resolve(String params) {
    final error = UnimplementedError('resolve not implemented');
    final stack = StackTrace.current;
    logAndHandleError(error, stack);
    throw error;
  }
}

// END GENERATED
