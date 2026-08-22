// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/suite/suite.dart';
import '../../../domain/services/suite_service.dart';

class SuiteProvider with Loggable, FailureHandler implements SuiteService {
  @override
  double score(Suite params) {
    final error = UnimplementedError('score not implemented');
    final stack = StackTrace.current;
    logAndHandleError(error, stack);
    throw error;
  }

  @override
  void evaluate(Suite params) {
    final error = UnimplementedError('evaluate not implemented');
    final stack = StackTrace.current;
    logAndHandleError(error, stack);
    throw error;
  }
}

// END GENERATED
