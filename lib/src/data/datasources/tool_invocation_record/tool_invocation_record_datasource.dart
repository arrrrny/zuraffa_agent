// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/tool_invocation_record/tool_invocation_record.dart';

abstract class ToolInvocationRecordDataSource with Loggable, FailureHandler {
  Future<ToolInvocationRecord> get(QueryParams<ToolInvocationRecord> params);
  Future<List<ToolInvocationRecord>> getList(
    ListQueryParams<ToolInvocationRecord> params,
  );
  Future<ToolInvocationRecord> create(
    ToolInvocationRecord toolInvocationRecord,
  );
  Future<ToolInvocationRecord> update(
    UpdateParams<String, ToolInvocationRecordPatch> params,
  );
  Future<void> delete(DeleteParams<String> params);
}

// END GENERATED
