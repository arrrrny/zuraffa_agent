// HAND-CURATED regression tests for the SessionBranch value object +
// SessionBranchProvider. Pattern mirrors spec 033.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/domain/entities/session_branch/session_branch.dart';
import 'package:zuraffa_agent/src/domain/services/session_branch_service.dart';
import 'package:zuraffa_agent/src/data/providers/session_branch/session_branch_provider.dart';

void main() {
  group('arrarrny/zuraffa_agent#3 - SessionBranch value equality', () {
    test('SessionBranch equality is value-based across all fields', () {
      final a = SessionBranch(id: 'id-a', sessionId: 'sess-1', forkedFromEntryId: 'ref-1', forkedAt: 10, isActive: true);
      final b = SessionBranch(id: 'id-a', sessionId: 'sess-1', forkedFromEntryId: 'ref-1', forkedAt: 10, isActive: true);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('SessionBranch inequality differs when a field changes', () {
      final a = SessionBranch(id: 'id-a', sessionId: 'sess-1', forkedFromEntryId: 'ref-1', forkedAt: 10, isActive: true);
      final b = SessionBranch(id: 'id-b', sessionId: 'sess-2', forkedFromEntryId: 'ref-2', forkedAt: 20, isActive: false);
      expect(a == b, isFalse);
    });
  });

  group('arrarrny/zuraffa_agent#3 - SessionBranch clean-arch layers', () {
    test('SessionBranchProvider is a SessionBranchService', () {
      final provider = SessionBranchProvider();
      expect(provider, isA<SessionBranchService>());
    });

    test('SessionBranchProvider.current returns the active branch', () async {
      final branch = await SessionBranchProvider().current(NoParams());
      expect(branch, isA<SessionBranch>());
      expect(branch.id, 'branch-default');
      expect(branch.sessionId, 'session-default');
      expect(branch.isActive, isTrue);
    });

    test('SessionBranchProvider.current returns a supplied active branch', () async {
      final active = SessionBranch(id: 'branch-x', sessionId: 'sess-x', forkedFromEntryId: 'entry-x', forkedAt: 42, isActive: false);
      expect(await SessionBranchProvider(active).current(NoParams()), active);
    });

    test('SessionBranchProvider.count returns 1', () async {
      expect(await SessionBranchProvider().count(NoParams()), 1);
    });
  });
}
