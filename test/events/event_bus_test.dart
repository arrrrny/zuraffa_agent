import 'package:test/test.dart';
import 'package:zuraffa_agent/src/events/event_bus.dart';

void main() {
  group('spec 013 — EventBus', () {
    test('A1: a subscriber to LLMChunkEvent receives each chunk event', () {
      final bus = EventBus();
      final received = <String>[];
      bus.on<LLMChunkEvent>((e) => received.add(e.chunk));
      bus.emit(LLMChunkEvent('hello'));
      bus.emit(LLMChunkEvent('world'));
      expect(received, ['hello', 'world']);
    });

    test('A2: multiple subscribers each receive an event, in registration order', () {
      final bus = EventBus();
      final order = <String>[];
      bus.on<LLMChunkEvent>((e) => order.add('s1:${e.chunk}'));
      bus.on<LLMChunkEvent>((e) => order.add('s2:${e.chunk}'));
      bus.on<LLMChunkEvent>((e) => order.add('s3:${e.chunk}'));
      bus.emit(LLMChunkEvent('x'));
      expect(order, ['s1:x', 's2:x', 's3:x']);
    });

    test('A3: a registered BeforeToolCallRequest handler receives the caller\'s args and its response is used', () async {
      // Case 1: the handler echoes the caller's payload and appends its own
      // decision. The assertion pins both directions of the round-trip: the
      // caller's `url` reached the handler, and the handler's merged map came
      // back. A bus that silently dropped the caller's event would fail this.
      final approveBus = EventBus();
      approveBus.registerHandler<BeforeToolCallRequest, BeforeToolCallResponse>((req) async {
        return BeforeToolCallResponse({...req.args, 'approved': true});
      });
      final approved = await approveBus.request<BeforeToolCallResponse>(
        BeforeToolCallRequest('web', {'url': 'x'}),
      );
      expect(approved.args, equals({'url': 'x', 'approved': true}));
      expect(approved.approved, isTrue);

      // Case 2: the `approved` flag is the handler's value, not a free default —
      // a declining handler must be reflected in the response.
      final denyBus = EventBus();
      denyBus.registerHandler<BeforeToolCallRequest, BeforeToolCallResponse>((req) async {
        return BeforeToolCallResponse({...req.args}, approved: false);
      });
      final denied = await denyBus.request<BeforeToolCallResponse>(
        BeforeToolCallRequest('web', {'url': 'y'}),
      );
      expect(denied.args, equals({'url': 'y'}));
      expect(denied.approved, isFalse);
    });

    test('A4: AgentController.publish delivers to all listeners like EventBus', () {
      final controller = AgentController();
      final received = <String>[];
      controller.listen<LLMChunkEvent>((e) => received.add(e.chunk));
      controller.publish(LLMChunkEvent('hi'));
      expect(received, ['hi']);
    });
  });
}
