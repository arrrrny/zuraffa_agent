// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/client_health/client_health.dart';

abstract class ClientHealthDataSource with Loggable, FailureHandler {
  Future<ClientHealth> get(QueryParams<ClientHealth> params);
  Future<ClientHealth> update(UpdateParams<String, ClientHealthPatch> params);
}

// END GENERATED
