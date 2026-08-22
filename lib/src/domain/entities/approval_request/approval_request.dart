/// Approval Request entity — request for user approval of confirm-tier tool.
///
/// Sent to approvalCallback when a confirm-tier tool is dispatched.
library;

import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'approval_request.zorphy.dart';
part 'approval_request.g.dart';

@Zorphy(generateJson: true, generateCompareTo: true)
abstract class $ApprovalRequest {
  String get toolName;
  Map<String, dynamic> get arguments;
  DateTime get requestedAt;
  int get timeoutMs;
  String get id;

}