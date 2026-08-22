// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/sub_agent_type/sub_agent_type.dart';
import '../../../domain/services/sub_agent_type_service.dart';

class SubAgentTypeProvider
    with Loggable, FailureHandler
    implements SubAgentTypeService {
  @override
  void execute(SubAgentType params) {
    final error = UnimplementedError('execute not implemented');
    final stack = StackTrace.current;
    logAndHandleError(error, stack);
    throw error;
  }
}

// END GENERATED
