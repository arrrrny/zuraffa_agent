/// Approval Callback — handles user approval for confirm-tier tools.
library;

import '../domain/entities/approval_request/approval_request.dart';

/// Type for approval callback function.
typedef ApprovalCallback = Future<bool> Function(ApprovalRequest request);

/// Default approval callback — always denies (safe default).
Future<bool> defaultApprovalCallback(ApprovalRequest request) async {
  return false;
}