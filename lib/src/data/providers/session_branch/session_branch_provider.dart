// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#3 (R1 - state & sessions).
//
// Concrete provider for the SessionBranch data layer. Returns the active
// branch snapshot for the running mission. Replaces the previous stub
// (spec 033).

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/session_branch/session_branch.dart';
import '../../../domain/services/session_branch_service.dart';

class SessionBranchProvider
    with Loggable, FailureHandler
    implements SessionBranchService {
  final SessionBranch _active;

  SessionBranchProvider([SessionBranch? active])
      : _active = active ??
            const SessionBranch(
              id: 'branch-default',
              sessionId: 'session-default',
              forkedFromEntryId: 'entry-root',
              forkedAt: 0,
              isActive: true,
            );

  @override
  Future<SessionBranch> current(NoParams params) async => _active;

  @override
  Future<int> count(NoParams params) async => 1;
}
