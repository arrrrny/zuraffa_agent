// Regression test for arrarrny/zuraffa_agent#2 (R1 — engine core: steering
// & follow-up queues).
//
// Asserts:
// - SteeringMessage is constructible with id + content + injectedAt and
//   has value-based equality.
// - SteeringQueue is constructible as an immutable snapshot with the
//   spec-exact fields: id + pending + processedCount + lastInjectedAt?.
// - The FIFO surface (head, isEmpty, pendingCount) reflects the pending
//   list state.
// - Value equality holds across all four fields of SteeringQueue.
// - The clean-arch layers (SteeringQueueService + SteeringQueueProvider)
//   are wired correctly and compile.
// - The provider's UnimplementedError stubs fire.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;

import 'package:zuraffa_agent/src/domain/entities/steering_message/steering_message.dart';
import 'package:zuraffa_agent/src/domain/entities/steering_queue/steering_queue.dart';
import 'package:zuraffa_agent/src/domain/services/steering_queue_service.dart';
import 'package:zuraffa_agent/src/data/providers/steering_queue/steering_queue_provider.dart';

void main() {
  group('arrarrny/zuraffa_agent#2 — SteeringMessage value object', () {
    test('SteeringMessage is constructible with id + content + injectedAt', () {
      final ts = DateTime.utc(2026, 8, 24, 9, 0, 0);
      final msg = SteeringMessage(
        id: 'msg-1',
        content: 'Actually, also summarise the result.',
        injectedAt: ts,
      );
      expect(msg.id, 'msg-1');
      expect(msg.content, 'Actually, also summarise the result.');
      expect(msg.injectedAt, ts);
    });

    test('SteeringMessage equality is value-based across all three fields', () {
      final ts = DateTime.utc(2026, 8, 24, 9, 0, 0);
      final a = SteeringMessage(id: 'msg-1', content: 'x', injectedAt: ts);
      final b = SteeringMessage(id: 'msg-1', content: 'x', injectedAt: ts);
      final c = SteeringMessage(id: 'msg-2', content: 'x', injectedAt: ts);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });
  });

  group('arrarrny/zuraffa_agent#2 — SteeringQueue immutable snapshot', () {
    test('SteeringQueue is constructible empty with no lastInjectedAt', () {
      final q = SteeringQueue(
        id: 'q-1',
        pending: const [],
        processedCount: 0,
      );
      expect(q.id, 'q-1');
      expect(q.pending, isEmpty);
      expect(q.processedCount, 0);
      expect(q.lastInjectedAt, isNull);
      expect(q.isEmpty, isTrue);
      expect(q.pendingCount, 0);
      expect(q.head, isNull);
    });

    test('SteeringQueue.head returns the first pending message (FIFO)', () {
      final ts1 = DateTime.utc(2026, 8, 24, 9, 0, 0);
      final ts2 = DateTime.utc(2026, 8, 24, 9, 1, 0);
      final m1 = SteeringMessage(id: 'm-1', content: 'first', injectedAt: ts1);
      final m2 = SteeringMessage(id: 'm-2', content: 'second', injectedAt: ts2);
      final q = SteeringQueue(
        id: 'q-1',
        pending: [m1, m2],
        processedCount: 3,
        lastInjectedAt: ts2,
      );
      expect(q.isEmpty, isFalse);
      expect(q.pendingCount, 2);
      expect(q.head, m1);
      expect(q.lastInjectedAt, ts2);
      expect(q.processedCount, 3);
    });

    test('SteeringQueue equality is value-based across all four fields', () {
      final ts = DateTime.utc(2026, 8, 24, 9, 0, 0);
      final m = SteeringMessage(id: 'm-1', content: 'x', injectedAt: ts);
      final a = SteeringQueue(
        id: 'q-1',
        pending: [m],
        processedCount: 5,
        lastInjectedAt: ts,
      );
      final b = SteeringQueue(
        id: 'q-1',
        pending: [m],
        processedCount: 5,
        lastInjectedAt: ts,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('SteeringQueue inequality differs on pending list contents', () {
      final ts = DateTime.utc(2026, 8, 24, 9, 0, 0);
      final m1 = SteeringMessage(id: 'm-1', content: 'x', injectedAt: ts);
      final m2 = SteeringMessage(id: 'm-2', content: 'y', injectedAt: ts);
      final a = SteeringQueue(
        id: 'q-1',
        pending: [m1],
        processedCount: 0,
      );
      final b = SteeringQueue(
        id: 'q-1',
        pending: [m2],
        processedCount: 0,
      );
      expect(a == b, isFalse);
    });
  });

  group('arrarrny/zuraffa_agent#2 — SteeringQueue clean-arch layers', () {
    test('SteeringQueueProvider is a SteeringQueueService', () {
      final provider = SteeringQueueProvider();
      expect(provider, isA<SteeringQueueService>());
    });

    test('SteeringQueueProvider.current throws UnimplementedError on NoParams', () {
      final provider = SteeringQueueProvider();
      expect(
        () => provider.current(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('SteeringQueueProvider.count throws UnimplementedError on NoParams', () {
      final provider = SteeringQueueProvider();
      expect(
        () => provider.count(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
