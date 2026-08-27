// Regression test for arrarrny/zuraffa_agent#1 (R2 — state & sessions).
//
// Asserts:
// - The AgentSession root entity is constructible with the spec-exact
//   fields: id + missionId? + rootEntryId + currentEntryId? +
//   parentSessionId? + createdAt + updatedAt.
// - The branching/forking surface (isBranch, isHead) reflects the
//   parentSessionId / currentEntryId state.
// - Value equality holds across all seven fields.
// - The clean-arch layers (AgentSessionService + AgentSessionProvider)
//   are wired correctly and the provider returns the active session.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;

import 'package:zuraffa_agent/src/domain/entities/agent_session/agent_session.dart';
import 'package:zuraffa_agent/src/domain/services/agent_session_service.dart';
import 'package:zuraffa_agent/src/data/providers/agent_session/agent_session_provider.dart';

void main() {
  group('arrarrny/zuraffa_agent#1 — AgentSession root entity (R2 sessions)', () {
    test('AgentSession is constructible with id + rootEntryId + timestamps', () {
      final createdAt = DateTime.utc(2026, 8, 24, 9, 0, 0);
      final session = AgentSession(
        id: 'sess-1',
        rootEntryId: 'entry-root',
        createdAt: createdAt,
        updatedAt: createdAt,
      );
      expect(session.id, 'sess-1');
      expect(session.rootEntryId, 'entry-root');
      expect(session.missionId, isNull);
      expect(session.currentEntryId, isNull);
      expect(session.parentSessionId, isNull);
      expect(session.createdAt, createdAt);
      expect(session.updatedAt, createdAt);
    });

    test('AgentSession.isBranch is true when parentSessionId is non-null', () {
      final ts = DateTime.utc(2026, 8, 24, 9, 0, 0);
      final primary = AgentSession(
        id: 'sess-primary',
        rootEntryId: 'r1',
        createdAt: ts,
        updatedAt: ts,
      );
      final fork = AgentSession(
        id: 'sess-fork',
        rootEntryId: 'r1',
        parentSessionId: 'sess-primary',
        createdAt: ts,
        updatedAt: ts,
      );
      expect(primary.isBranch, isFalse);
      expect(fork.isBranch, isTrue);
    });

    test('AgentSession.isHead is true when currentEntryId is non-null', () {
      final ts = DateTime.utc(2026, 8, 24, 9, 0, 0);
      final empty = AgentSession(
        id: 'sess-empty',
        rootEntryId: 'r1',
        createdAt: ts,
        updatedAt: ts,
      );
      final head = AgentSession(
        id: 'sess-head',
        rootEntryId: 'r1',
        currentEntryId: 'entry-3',
        createdAt: ts,
        updatedAt: ts,
      );
      expect(empty.isHead, isFalse);
      expect(head.isHead, isTrue);
    });

    test('AgentSession equality is value-based across all seven fields', () {
      final ts1 = DateTime.utc(2026, 8, 24, 9, 0, 0);
      final ts2 = DateTime.utc(2026, 8, 24, 9, 5, 0);
      final a = AgentSession(
        id: 'sess-1',
        missionId: 'mission-9',
        rootEntryId: 'r1',
        currentEntryId: 'entry-3',
        parentSessionId: 'sess-0',
        createdAt: ts1,
        updatedAt: ts2,
      );
      final b = AgentSession(
        id: 'sess-1',
        missionId: 'mission-9',
        rootEntryId: 'r1',
        currentEntryId: 'entry-3',
        parentSessionId: 'sess-0',
        createdAt: ts1,
        updatedAt: ts2,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('AgentSession inequality differs on any field', () {
      final ts = DateTime.utc(2026, 8, 24, 9, 0, 0);
      final base = AgentSession(
        id: 'sess-1',
        rootEntryId: 'r1',
        createdAt: ts,
        updatedAt: ts,
      );
      // Differ on id
      expect(
        base ==
            AgentSession(
              id: 'sess-2',
              rootEntryId: 'r1',
              createdAt: ts,
              updatedAt: ts,
            ),
        isFalse,
      );
      // Differ on rootEntryId
      expect(
        base ==
            AgentSession(
              id: 'sess-1',
              rootEntryId: 'r2',
              createdAt: ts,
              updatedAt: ts,
            ),
        isFalse,
      );
      // Differ on parentSessionId (branch vs primary)
      expect(
        base ==
            AgentSession(
              id: 'sess-1',
              rootEntryId: 'r1',
              parentSessionId: 'sess-0',
              createdAt: ts,
              updatedAt: ts,
            ),
        isFalse,
      );
    });
  });

  group('arrarrny/zuraffa_agent#1 — AgentSession clean-arch layers', () {
    test('AgentSessionProvider is an AgentSessionService', () {
      expect(AgentSessionProvider(), isA<AgentSessionService>());
    });

    test('AgentSessionProvider.current returns the active session', () async {
      final session = await AgentSessionProvider().current(NoParams());
      expect(session, isA<AgentSession>());
      expect(session.id, 'default');
      expect(session.rootEntryId, 'root');
    });

    test('AgentSessionProvider.count returns 1', () async {
      expect(await AgentSessionProvider().count(NoParams()), 1);
    });
  });
}
