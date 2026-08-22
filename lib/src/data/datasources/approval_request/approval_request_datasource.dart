// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/approval_request/approval_request.dart';

abstract class ApprovalRequestDataSource with Loggable, FailureHandler {
  Future<ApprovalRequest> get(QueryParams<ApprovalRequest> params);
  Future<ApprovalRequest> update(
    UpdateParams<String, ApprovalRequestPatch> params,
  );
  Future<ApprovalRequest> toggle(
    ToggleParams<String, Field<ApprovalRequest, dynamic>> params,
  );
}

// END GENERATED
