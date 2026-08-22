// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/services/fallback_chain_service.dart';

class FallbackChainProvider
    with Loggable, FailureHandler
    implements FallbackChainService {
  @override
  String selectProvider() {
    final error = UnimplementedError('selectProvider not implemented');
    final stack = StackTrace.current;
    logAndHandleError(error, stack);
    throw error;
  }

  @override
  void recordFailure(String params) {
    final error = UnimplementedError('recordFailure not implemented');
    final stack = StackTrace.current;
    logAndHandleError(error, stack);
    throw error;
  }
}

// END GENERATED
