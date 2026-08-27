// Spec 033 — SteeringQueue + SteeringMessage semantics tests (TDD cycles 1-3).
//
// Traces: tdd/test-list.md A1..A3, U1, U2, U4 (cycle 1: defensive
// immutability + enqueue), A4..A6, U3 (cycle 2: pop dispatch transition),
// A7..A9, U5, U6 (cycle 3: persistence contract).
//
// The transition tests are red against the scaffolded entity today: the
// scaffold ships the four-field snapshot and the head/isEmpty/pendingCount
// reads but no enqueue/pop methods — its own doc comments describe the
// snapshot mutation model ("appending a message and returning a new
// snapshot", "pops messages FIFO... processedCount increments per pop")
// that these tests drive through the public API. The defensive-copy tests
// are assertion-level reds: the scaffold stores the caller's list
// reference, so mutating the source list mutates the queue.

import 'package:test/test.dart';

import 'package:zuraffa_agent/src/domain/entities/steering_message/steering_message.dart';
import 'package:zuraffa_agent/src/domain/entities/steering_queue/steering_queue.dart';

void main() {
  final t1 = DateTime.utc(2026, 8, 24, 9, 0, 0);
  final t2 = DateTime.utc(2026, 8, 24, 9, 1, 0);
  final t3 = DateTime.utc(2026, 8, 24, 9, 2, 0);

  SteeringMessage msg(String id, String content, DateTime at) =>
      SteeringMessage(id: id, content: content, injectedAt: at);

  group('spec 033 — SteeringQueue defensive immutability + enqueue (cycle 1)', () {
    test('A1: enqueue on an empty queue yields head==message, isEmpty false, lastInjectedAt stamped', () {
      final queue = SteeringQueue(id: 'q-1', pending: const [], processedCount: 0);
      final m = msg('m-1', 'also summarise', t1);
      final enqueued = queue.enqueue(m);
      expect(enqueued.pendingCount, 1);
      expect(enqueued.head, m);
      expect(enqueued.isEmpty, isFalse);
      expect(enqueued.lastInjectedAt, t1);
    });

    test('A2: enqueue on a loaded queue appends FIFO (head stays the first)', () {
      final m1 = msg('m-1', 'first', t1);
      final m2 = msg('m-2', 'second', t2);
      final queue = SteeringQueue(id: 'q-1', pending: [m1], processedCount: 0, lastInjectedAt: t1);
      final enqueued = queue.enqueue(m2);
      expect(enqueued.pending, [m1, m2]);
      expect(enqueued.head, m1, reason: 'FIFO — head stays the first');
      expect(enqueued.lastInjectedAt, t2, reason: 'stamp moves to the newest injection');
    });

    test('A3: enqueue leaves the source snapshot fully unchanged (no state lost mid-turn)', () {
      final m1 = msg('m-1', 'first', t1);
      final queue = SteeringQueue(id: 'q-1', pending: [m1], processedCount: 3, lastInjectedAt: t1);
      queue.enqueue(msg('m-2', 'second', t2));
      expect(queue.pending, [m1]);
      expect(queue.processedCount, 3);
      expect(queue.lastInjectedAt, t1);
    });

    test('U1: mutating the constructor source list after construction does not affect the queue', () {
      final source = <SteeringMessage>[msg('m-1', 'first', t1)];
      final queue = SteeringQueue(id: 'q-1', pending: source, processedCount: 0);
      source.add(msg('m-2', 'smuggled', t2));
      expect(queue.pendingCount, 1, reason: 'the queue defensively copied its pending list');
    });

    test('U2: direct writes to queue.pending throw (unmodifiable view)', () {
      final queue = SteeringQueue(id: 'q-1', pending: [msg('m-1', 'first', t1)], processedCount: 0);
      expect(
        () => queue.pending.add(msg('m-2', 'smuggled', t2)),
        throwsA(anyOf(isA<UnsupportedError>(), isA<StateError>())),
        reason: 'the pending list is an unmodifiable view',
      );
    });

    test('U4: enqueue preserves processedCount and id', () {
      final queue = SteeringQueue(id: 'q-1', pending: [msg('m-1', 'first', t1)], processedCount: 7, lastInjectedAt: t1);
      final enqueued = queue.enqueue(msg('m-2', 'second', t2));
      expect(enqueued.id, 'q-1');
      expect(enqueued.processedCount, 7);
    });
  });

  group('spec 033 — SteeringQueue pop dispatch transition (cycle 2)', () {
    test('A4: pop returns the head and the drained queue with processedCount + 1', () {
      final m1 = msg('m-1', 'first', t1);
      final m2 = msg('m-2', 'second', t2);
      final queue = SteeringQueue(id: 'q-1', pending: [m1, m2], processedCount: 3, lastInjectedAt: t2);
      final result = queue.pop();
      expect(result.message, m1);
      expect(result.queue.pending, [m2]);
      expect(result.queue.processedCount, 4);
      expect(result.queue.id, 'q-1');
    });

    test('A5: pop on an empty queue throws StateError naming the queue id', () {
      final queue = SteeringQueue(id: 'q-9', pending: const [], processedCount: 0);
      expect(
        () => queue.pop(),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('q-9'))),
      );
    });

    test('A6: double-pop drains FIFO and ends empty with processedCount + 2', () {
      final m1 = msg('m-1', 'first', t1);
      final m2 = msg('m-2', 'second', t2);
      final queue = SteeringQueue(id: 'q-1', pending: [m1, m2], processedCount: 0, lastInjectedAt: t2);
      final first = queue.pop();
      final second = first.queue.pop();
      expect(first.message, m1);
      expect(second.message, m2);
      expect(second.queue.isEmpty, isTrue);
      expect(second.queue.processedCount, 2);
    });

    test('U3: pop preserves lastInjectedAt on the drained queue', () {
      final m1 = msg('m-1', 'first', t1);
      final queue = SteeringQueue(id: 'q-1', pending: [m1], processedCount: 0, lastInjectedAt: t2);
      final drained = queue.pop().queue;
      expect(drained.lastInjectedAt, t2);
    });
  });

  group('spec 033 — SteeringQueue + SteeringMessage persistence contract (cycle 3)', () {
    test('A7: a populated queue round-trips JSON incl. FIFO order and processedCount', () {
      final m1 = msg('m-1', 'first', t1);
      final m2 = msg('m-2', 'second', t2);
      final queue = SteeringQueue(id: 'q-1', pending: [m1, m2], processedCount: 3, lastInjectedAt: t2);
      final parsed = SteeringQueue.fromJson(queue.toJson());
      expect(parsed, equals(queue));
      expect(parsed.pending.first.content, 'first', reason: 'FIFO order survives the round-trip');
      expect(parsed.processedCount, 3);
    });

    test('A8: an empty queue serializes lastInjectedAt absent and restores null', () {
      final queue = SteeringQueue(id: 'q-1', pending: const [], processedCount: 0);
      final json = queue.toJson();
      expect(json.containsKey('lastInjectedAt'), isFalse);
      final parsed = SteeringQueue.fromJson(json);
      expect(parsed.lastInjectedAt, isNull);
      expect(parsed, equals(queue));
    });

    test('A9: a steering message round-trips JSON (id, content, injectedAt)', () {
      final m = msg('m-1', 'also summarise the result', t1);
      final parsed = SteeringMessage.fromJson(m.toJson());
      expect(parsed, equals(m));
      expect(parsed.injectedAt.isUtc, isTrue);
      expect(parsed.injectedAt, t1);
    });

    test('U5: malformed queue JSON throws ArgumentError (missing id, non-list pending, non-map entry)', () {
      expect(
        () => SteeringQueue.fromJson(const {'pending': <dynamic>[], 'processedCount': 0}),
        throwsA(isA<ArgumentError>()),
        reason: 'missing id',
      );
      expect(
        () => SteeringQueue.fromJson(const {'id': 'q', 'pending': 'nope', 'processedCount': 0}),
        throwsA(isA<ArgumentError>()),
        reason: 'non-list pending',
      );
      expect(
        () => SteeringQueue.fromJson(const {'id': 'q', 'pending': <dynamic>['nope'], 'processedCount': 0}),
        throwsA(isA<ArgumentError>()),
        reason: 'non-map pending entry',
      );
    });

    test('U6: malformed message JSON throws ArgumentError naming the key', () {
      expect(
        () => SteeringMessage.fromJson(const {'content': 'x', 'injectedAt': '2026-08-24T09:00:00.000Z'}),
        throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'id')),
        reason: 'missing id',
      );
      expect(
        () => SteeringMessage.fromJson(const {'id': 'm', 'content': 42, 'injectedAt': '2026-08-24T09:00:00.000Z'}),
        throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'content')),
        reason: 'ill-typed content',
      );
    });
  });
}
