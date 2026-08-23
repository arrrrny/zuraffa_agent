// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/dispatch_tool/dispatch_tool.dart';

abstract class DispatchToolDataSource with Loggable, FailureHandler {
  Future<DispatchTool> get(QueryParams<DispatchTool> params);
  Future<DispatchTool> update(UpdateParams<String, DispatchToolPatch> params);
}

// END GENERATED
