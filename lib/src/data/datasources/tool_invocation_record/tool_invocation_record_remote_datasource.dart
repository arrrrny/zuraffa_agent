// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/tool_invocation_record/tool_invocation_record.dart';
import 'tool_invocation_record_datasource.dart';

class ToolInvocationRecordRemoteDataSource
    with Loggable, FailureHandler
    implements ToolInvocationRecordDataSource {
  @override
  Future<ToolInvocationRecord> get(
    QueryParams<ToolInvocationRecord> params,
  ) async {
    throw UnimplementedError('Implement remote get');
  }

  @override
  Future<List<ToolInvocationRecord>> getList(
    ListQueryParams<ToolInvocationRecord> params,
  ) async {
    throw UnimplementedError('Implement remote getList');
  }

  @override
  Future<ToolInvocationRecord> create(
    ToolInvocationRecord toolInvocationRecord,
  ) async {
    throw UnimplementedError('Implement remote create');
  }

  @override
  Future<ToolInvocationRecord> update(
    UpdateParams<String, ToolInvocationRecordPatch> params,
  ) async {
    throw UnimplementedError('Implement remote update');
  }

  @override
  Future<void> delete(DeleteParams<String> params) async {
    throw UnimplementedError('Implement remote delete');
  }
}

// END GENERATED
