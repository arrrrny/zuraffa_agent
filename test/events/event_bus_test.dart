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
  });
}
