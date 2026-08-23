// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/suite/suite.dart';

abstract class SuiteDataSource with Loggable, FailureHandler {
  Future<Suite> get(QueryParams<Suite> params);
  Future<Suite> update(UpdateParams<String, SuitePatch> params);
}

// END GENERATED
