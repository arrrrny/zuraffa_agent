// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/approval_request/approval_request.dart';
import 'approval_request_datasource.dart';

class ApprovalRequestRemoteDataSource
    with Loggable, FailureHandler
    implements ApprovalRequestDataSource {
  @override
  Future<ApprovalRequest> get(QueryParams<ApprovalRequest> params) async {
    throw UnimplementedError('Implement remote get');
  }

  @override
  Future<ApprovalRequest> update(
    UpdateParams<String, ApprovalRequestPatch> params,
  ) async {
    throw UnimplementedError('Implement remote update');
  }

  @override
  Future<ApprovalRequest> toggle(
    ToggleParams<String, Field<ApprovalRequest, dynamic>> params,
  ) async {
    throw UnimplementedError('Implement remote toggle');
  }
}

// END GENERATED
