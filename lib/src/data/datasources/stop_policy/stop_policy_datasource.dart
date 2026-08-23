// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/stop_policy/stop_policy.dart';

abstract class StopPolicyDataSource with Loggable, FailureHandler {
  Future<StopPolicy> get(QueryParams<StopPolicy> params);
  Future<StopPolicy> update(UpdateParams<String, StopPolicyPatch> params);
}

// END GENERATED
