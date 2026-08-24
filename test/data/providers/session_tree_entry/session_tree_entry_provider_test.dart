// HAND-CURATED regression tests for the SessionTreeEntry value object +
// SessionTreeEntryProvider stub. Pattern mirrors spec 033.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/domain/entities/session_tree_entry/session_tree_entry.dart';
import 'package:zuraffa_agent/src/domain/services/session_tree_entry_service.dart';
import 'package:zuraffa_agent/src/data/providers/session_tree_entry/session_tree_entry_provider.dart';

void main() {
  group('arrarrny/zuraffa_agent#3 - SessionTreeEntry value equality', () {
    test('SessionTreeEntry equality is value-based across all fields', () {
      final a = SessionTreeEntry(id: 'id-a', sessionId: 'sess-1', parentEntryId: null, createdAt: 10);
      final b = SessionTreeEntry(id: 'id-a', sessionId: 'sess-1', parentEntryId: null, createdAt: 10);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('SessionTreeEntry inequality differs when a field changes', () {
      final a = SessionTreeEntry(id: 'id-a', sessionId: 'sess-1', parentEntryId: null, createdAt: 10);
      final b = SessionTreeEntry(id: 'id-b', sessionId: 'sess-2', parentEntryId: null, createdAt: 20);
      expect(a == b, isFalse);
    });
  });

  group('arrarrny/zuraffa_agent#3 - SessionTreeEntry clean-arch layers', () {
    test('SessionTreeEntryProvider is a SessionTreeEntryService', () {
      final provider = SessionTreeEntryProvider();
      expect(provider, isA<SessionTreeEntryService>());
    });

    test('SessionTreeEntryProvider.current throws UnimplementedError on NoParams', () {
      final provider = SessionTreeEntryProvider();
      expect(
        () => provider.current(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('SessionTreeEntryProvider.count throws UnimplementedError on NoParams', () {
      final provider = SessionTreeEntryProvider();
      expect(
        () => provider.count(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
