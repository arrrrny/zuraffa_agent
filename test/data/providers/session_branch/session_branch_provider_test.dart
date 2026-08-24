// HAND-CURATED regression tests for the SessionBranch value object +
// SessionBranchProvider stub. Pattern mirrors spec 033.

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

    test('SessionBranchProvider.current throws UnimplementedError on NoParams', () {
      final provider = SessionBranchProvider();
      expect(
        () => provider.current(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('SessionBranchProvider.count throws UnimplementedError on NoParams', () {
      final provider = SessionBranchProvider();
      expect(
        () => provider.count(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
