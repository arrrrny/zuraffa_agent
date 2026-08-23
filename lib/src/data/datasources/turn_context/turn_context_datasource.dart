// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/turn_context/turn_context.dart';

abstract class TurnContextDataSource with Loggable, FailureHandler {
  Future<TurnContext> get(QueryParams<TurnContext> params);
  Future<TurnContext> update(UpdateParams<String, TurnContextPatch> params);
}

// END GENERATED
