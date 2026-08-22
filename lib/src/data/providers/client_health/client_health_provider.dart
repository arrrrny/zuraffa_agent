// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/services/client_health_service.dart';

class ClientHealthProvider
    with Loggable, FailureHandler
    implements ClientHealthService {
  @override
  void markFailure(String params) {
    final error = UnimplementedError('markFailure not implemented');
    final stack = StackTrace.current;
    logAndHandleError(error, stack);
    throw error;
  }

  @override
  bool isHealthy(String params) {
    final error = UnimplementedError('isHealthy not implemented');
    final stack = StackTrace.current;
    logAndHandleError(error, stack);
    throw error;
  }
}

// END GENERATED
