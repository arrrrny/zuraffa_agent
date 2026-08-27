// Spec 032 — AgentSession aggregate semantics tests (TDD cycles 1-3).
//
// Traces: tdd/test-list.md A1..A3, U1 (cycle 1: appendEntry cursor
// transition), A4..A6, U2, U3 (cycle 2: fork branch transition), A7..A9,
// U4, U5 (cycle 3: persistence contract).
//
// The transition tests are red against the scaffolded entity today: the
// scaffold ships the seven-field surface and the isBranch/isHead reads but
// no transition methods — its own doc comments describe the cursor advance
// ("the engine initialises it to rootEntryId on the first append") and the
// branch link ("non-null when this session is a fork/branch of another")
// that these tests drive through the public API.

import 'package:test/test.dart';

import 'package:zuraffa_agent/src/domain/entities/agent_session/agent_session.dart';

void main() {
  final t0 = DateTime.utc(2026, 8, 24, 9, 0, 0);
  final t1 = DateTime.utc(2026, 8, 24, 9, 5, 0);
  final t2 = DateTime.utc(2026, 8, 24, 9, 10, 0);

  AgentSession fresh() => AgentSession(
        id: 'sess-1',
        rootEntryId: 'entry-root',
        createdAt: t0,
        updatedAt: t0,
      );

  group('spec 032 — AgentSession appendEntry cursor transition (cycle 1)', () {
    test('A1: appendEntry on a fresh session initialises the cursor and stamps updatedAt', () {
      final session = fresh();
      final advanced = session.appendEntry('entry-1', at: t1);
      expect(advanced.currentEntryId, 'entry-1');
      expect(advanced.updatedAt, t1);
      expect(advanced.isHead, isTrue);
      // Everything the transition must not touch.
      expect(advanced.id, session.id);
      expect(advanced.missionId, isNull);
      expect(advanced.rootEntryId, session.rootEntryId);
      expect(advanced.parentSessionId, isNull);
      expect(advanced.createdAt, t0);
    });

    test('A2: appendEntry on a headed session advances the cursor; isHead stays true', () {
      final headed = fresh().appendEntry('entry-1', at: t1);
      final advanced = headed.appendEntry('entry-2', at: t2);
      expect(advanced.currentEntryId, 'entry-2');
      expect(advanced.isHead, isTrue);
      expect(advanced.updatedAt, t2);
    });

    test('A3: appendEntry rejects an empty entry id with ArgumentError', () {
      expect(() => fresh().appendEntry(''), throwsArgumentError);
    });

    test('U1: appendEntry never mutates the source snapshot', () {
      final session = fresh().appendEntry('entry-1', at: t1);
      final advanced = session.appendEntry('entry-2', at: t2);
      expect(session.currentEntryId, 'entry-1', reason: 'source cursor unchanged');
      expect(session.updatedAt, t1, reason: 'source updatedAt unchanged');
      expect(identical(advanced, session), isFalse);
    });
  });

  group('spec 032 — AgentSession fork branch transition (cycle 2)', () {
    test('A4: fork links the child via parentSessionId with the cursor at the current head', () {
      final parent = fresh().appendEntry('entry-3', at: t1);
      final child = parent.fork(sessionId: 'sess-2', at: t2);
      expect(child.id, 'sess-2');
      expect(child.parentSessionId, 'sess-1');
      expect(child.isBranch, isTrue);
      expect(child.currentEntryId, 'entry-3', reason: 'fork point = current head');
      expect(child.createdAt, t2);
      expect(child.updatedAt, t2);
    });

    test('A5: fork of a fresh session falls back to the root anchor as the fork point', () {
      final parent = fresh();
      final child = parent.fork(sessionId: 'sess-2', at: t1);
      expect(child.currentEntryId, 'entry-root', reason: 'fresh session forks at the root anchor');
      expect(child.isHead, isTrue);
    });

    test('A6: fork inherits the parent missionId', () {
      final parent = AgentSession(
        id: 'sess-1',
        missionId: 'mission-9',
        rootEntryId: 'entry-root',
        createdAt: t0,
        updatedAt: t0,
      );
      final child = parent.fork(sessionId: 'sess-2', at: t1);
      expect(child.missionId, 'mission-9');
    });

    test('U2: fork never mutates the source session', () {
      final parent = fresh().appendEntry('entry-1', at: t1);
      parent.fork(sessionId: 'sess-2', at: t2);
      expect(parent.isBranch, isFalse, reason: 'source stays a primary session');
      expect(parent.currentEntryId, 'entry-1');
      expect(parent.updatedAt, t1);
    });

    test('U3: fork preserves rootEntryId — the branch grows inside the same entry tree', () {
      final parent = fresh().appendEntry('entry-2', at: t1);
      final child = parent.fork(sessionId: 'sess-2', at: t2);
      expect(child.rootEntryId, parent.rootEntryId);
    });
  });

  group('spec 032 — AgentSession persistence contract (cycle 3)', () {
    test('A7: a fully-populated session round-trips JSON field-exactly', () {
      final session = AgentSession(
        id: 'sess-1',
        missionId: 'mission-9',
        rootEntryId: 'entry-root',
        currentEntryId: 'entry-3',
        parentSessionId: 'sess-0',
        createdAt: t0,
        updatedAt: t1,
      );
      final json = session.toJson();
      final parsed = AgentSession.fromJson(json);
      expect(parsed, equals(session));
      expect(parsed.hashCode, session.hashCode);
      expect(parsed.missionId, 'mission-9');
      expect(parsed.currentEntryId, 'entry-3');
      expect(parsed.parentSessionId, 'sess-0');
    });

    test('A8: a minimal session serializes null optionals absent and restores them null', () {
      final session = fresh();
      final json = session.toJson();
      expect(json.containsKey('missionId'), isFalse);
      expect(json.containsKey('currentEntryId'), isFalse);
      expect(json.containsKey('parentSessionId'), isFalse);
      final parsed = AgentSession.fromJson(json);
      expect(parsed.missionId, isNull);
      expect(parsed.currentEntryId, isNull);
      expect(parsed.parentSessionId, isNull);
      expect(parsed, equals(session));
    });

    test('A9: malformed JSON throws ArgumentError naming the offending key', () {
      expect(
        () => AgentSession.fromJson(const {'rootEntryId': 'r', 'createdAt': '2026-08-24T09:00:00.000Z', 'updatedAt': '2026-08-24T09:00:00.000Z'}),
        throwsA(isA<ArgumentError>()),
        reason: 'missing id',
      );
      expect(
        () => AgentSession.fromJson(const {'id': 's', 'createdAt': '2026-08-24T09:00:00.000Z', 'updatedAt': '2026-08-24T09:00:00.000Z'}),
        throwsA(isA<ArgumentError>()),
        reason: 'missing rootEntryId',
      );
      expect(
        () => AgentSession.fromJson(const {'id': 's', 'rootEntryId': 'r', 'updatedAt': '2026-08-24T09:00:00.000Z'}),
        throwsA(isA<ArgumentError>()),
        reason: 'missing createdAt',
      );
      expect(
        () => AgentSession.fromJson(const {'id': 's', 'rootEntryId': 'r', 'createdAt': '2026-08-24T09:00:00.000Z'}),
        throwsA(isA<ArgumentError>()),
        reason: 'missing updatedAt',
      );
    });

    test('U4: fromJson restores UTC timestamps exactly (instant + zone preserved)', () {
      final session = fresh().appendEntry('entry-1', at: t1);
      final parsed = AgentSession.fromJson(session.toJson());
      expect(parsed.createdAt.isUtc, isTrue);
      expect(parsed.updatedAt.isUtc, isTrue);
      expect(parsed.createdAt, t0);
      expect(parsed.updatedAt, t1);
    });

    test('U5: fromJson rejects an ill-typed id (non-string) with ArgumentError naming it', () {
      expect(
        () => AgentSession.fromJson(const {
          'id': 42,
          'rootEntryId': 'r',
          'createdAt': '2026-08-24T09:00:00.000Z',
          'updatedAt': '2026-08-24T09:00:00.000Z',
        }),
        throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'id')),
      );
    });
  });
}
