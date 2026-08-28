// Tests for the engine event bus (spec 075): typed synchronous pub/sub
// over the sealed EngineEvent union, with error isolation and replay.

import 'package:test/test.dart';

import 'package:zuraffa_agent/src/engine/engine_event_bus.dart';
import 'package:zuraffa_agent/src/engine/events/engine_event.dart';

DateTime get at => DateTime.utc(2026, 8, 29, 12);

TurnStarted turnStart([int n = 1]) =>
    TurnStarted(emittedAt: at, turnId: 't$n');

TurnCompleted turnComplete() => TurnCompleted(emittedAt: at);

ToolCallStarted toolStart() =>
    ToolCallStarted(emittedAt: at, toolName: 'fs_read', callId: 'c1');

void main() {
  group('spec 075 — EngineEventBus', () {
    test('typed subscriptions filter by exact runtime type', () {
      final bus = EngineEventBus();
      final turns = <TurnStarted>[];
      final everything = <EngineEvent>[];

      bus.subscribe<TurnStarted>(turns.add);
      bus.subscribe<EngineEvent>(everything.add);

      bus.publish(turnStart());
      bus.publish(turnComplete());
      bus.publish(toolStart());

      expect(turns, hasLength(1), reason: 'only the TurnStarted matched');
      expect(turns.single.turnId, 't1');
      expect(everything, hasLength(3),
          reason: 'EngineEvent wildcard receives all');

      // Non-matching publishes are FILTERED, not swallowed-as-errors: the
      // error hook must stay silent when a typed subscriber simply isn't
      // interested. (Pins the type filter as behavior, not just the cast
      // inside the invoker — mutation M2's original survivor.)
      var hookFired = 0;
      final quiet = EngineEventBus(
        onSubscriberError: (_, _) => hookFired++,
      );
      quiet.subscribe<TurnStarted>((_) {});
      quiet.publish(turnComplete());
      quiet.publish(toolStart());
      expect(hookFired, 0,
          reason: 'non-matching events are filtered before the handler');
    });

    test('delivery follows registration order', () {
      final bus = EngineEventBus();
      final order = <String>[];

      bus.subscribe<TurnStarted>((_) => order.add('first'));
      bus.subscribe<TurnStarted>((_) => order.add('second'));
      bus.subscribe<TurnStarted>((_) => order.add('third'));

      bus.publish(turnStart());

      expect(order, ['first', 'second', 'third']);
    });

    test('one publish fans out to many subscribers', () {
      final bus = EngineEventBus();
      var typedGot = 0;
      var wildcardGot = 0;
      var otherTypedGot = 0;

      bus.subscribe<ToolCallStarted>((_) => typedGot++);
      bus.subscribe<EngineEvent>((_) => wildcardGot++);
      bus.subscribe<ToolCallStarted>((_) => otherTypedGot++);

      bus.publish(toolStart());

      expect(typedGot, 1);
      expect(otherTypedGot, 1, reason: 'BOTH same-type subscribers fire');
      expect(wildcardGot, 1);
    });

    test('a throwing subscriber never breaks delivery', () {
      Object? caughtError;
      EngineEvent? caughtEvent;
      final bus = EngineEventBus(
        onSubscriberError: (error, event) {
          caughtError = error;
          caughtEvent = event;
        },
      );
      var secondGot = 0;

      bus.subscribe<TurnStarted>((_) => throw StateError('broken observer'));
      bus.subscribe<TurnStarted>((_) => secondGot++);

      // Must not throw despite the first subscriber blowing up.
      bus.publish(turnStart());

      expect(secondGot, 1, reason: 'later subscriber still received it');
      expect(caughtError, isA<StateError>());
      expect(caughtEvent, isA<TurnStarted>());

      // And with no hook configured, isolation still holds.
      final silent = EngineEventBus();
      var stillGot = 0;
      silent.subscribe<ToolCallStarted>((_) => throw StateError('boom'));
      silent.subscribe<ToolCallStarted>((_) => stillGot++);
      silent.publish(toolStart());
      expect(stillGot, 1);
    });

    test('cancel stops delivery and frees the slot', () {
      final bus = EngineEventBus();
      var count = 0;

      final sub = bus.subscribe<TurnStarted>((_) => count++);
      expect(sub.isActive, isTrue);
      expect(bus.subscriberCount, 1);

      bus.publish(turnStart());
      expect(count, 1);

      sub.cancel();
      expect(sub.isActive, isFalse);
      expect(bus.subscriberCount, 0, reason: 'slot freed');

      bus.publish(turnStart());
      expect(count, 1, reason: 'no delivery after cancel');

      // Double cancel is safe.
      sub.cancel();
      expect(sub.isActive, isFalse);

      // A new subscriber still receives events after an old one cancelled.
      var fresh = 0;
      bus.subscribe<TurnStarted>((_) => fresh++);
      bus.publish(turnStart());
      expect(fresh, 1);
    });

    test('subscriberCount tracks live subscriptions', () {
      final bus = EngineEventBus();
      expect(bus.subscriberCount, 0);

      final a = bus.subscribe<TurnStarted>( (_) {});
      final b = bus.subscribe<EngineEvent>((_) {});
      expect(bus.subscriberCount, 2);

      a.cancel();
      expect(bus.subscriberCount, 1);

      b.cancel();
      expect(bus.subscriberCount, 0);
    });

    test('replay broadcasts history to current subscribers', () {
      final bus = EngineEventBus();
      final early = <EngineEvent>[];

      final history = [turnStart(1), turnStart(2), turnStart(3)];
      for (final event in history) {
        bus.publish(event);
      }

      bus.subscribe<EngineEvent>(early.add);
      final late = <TurnStarted>[];
      final sub = bus.subscribe<TurnStarted>(late.add);

      bus.replay(history);

      // The late subscriber sees the full history, in order.
      expect(late.map((e) => e.turnId), ['t1', 't2', 't3']);
      // Replay is a broadcast: earlier subscribers see it again too.
      expect(early, hasLength(3));

      sub.cancel();

      // Composes with any Iterable<EngineEvent> source — the
      // EngineEventLog.events shape.
      final logShape = [turnComplete(), toolStart()];
      final mixed = <EngineEvent>[];
      bus.subscribe<EngineEvent>(mixed.add);
      bus.replay(logShape);
      expect(mixed.map((e) => e.runtimeType),
          [TurnCompleted, ToolCallStarted]);
    });

    test('onEvent bridge: any emitter becomes a multi-subscriber source',
        () {
      final bus = EngineEventBus();
      final turns = <TurnStarted>[];
      final tools = <ToolCallStarted>[];
      final all = <EngineEvent>[];

      bus.subscribe<TurnStarted>(turns.add);
      bus.subscribe<ToolCallStarted>(tools.add);
      bus.subscribe<EngineEvent>(all.add);

      // The bridge: an engine runtime's onEvent callback pointed at the
      // bus — one emission, three independent consumers.
      final onEvent = bus.publish;

      onEvent(turnStart(9));
      onEvent(toolStart());

      expect(turns, hasLength(1));
      expect(tools, hasLength(1));
      expect(all, hasLength(2));
    });
  });
}
