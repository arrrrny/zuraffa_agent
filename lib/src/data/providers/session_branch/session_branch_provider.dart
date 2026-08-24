// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#3 (R1 - state & sessions).
//
// Concrete provider stub for the SessionBranch data layer. Mirrors the
// SteeringQueueProvider pattern (spec 033) and ToolResultProvider
// (spec 031): bodies throw UnimplementedError so the file is analyzable
// without forcing real I/O.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/session_branch/session_branch.dart';
import '../../../domain/services/session_branch_service.dart';

class SessionBranchProvider
    with Loggable, FailureHandler
    implements SessionBranchService {
  SessionBranchProvider();

  @override
  Future<SessionBranch> current(NoParams params) async =>
      throw UnimplementedError('Implement SessionBranchProvider.current');

  @override
  Future<int> count(NoParams params) async =>
      throw UnimplementedError('Implement SessionBranchProvider.count');
}
