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

    test('A3: a registered BeforeToolCallRequest handler response is used', () async {
      final bus = EventBus();
      bus.registerHandler<BeforeToolCallRequest, BeforeToolCallResponse>((req) async {
        return BeforeToolCallResponse({...req.args, 'approved': true});
      });
      final resp = await bus.request<BeforeToolCallResponse>(
        BeforeToolCallRequest('web', {'url': 'x'}),
      );
      expect(resp.approved, isTrue);
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
