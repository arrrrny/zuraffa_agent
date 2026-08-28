// Spec 078 — request/response pattern: completing spec 013.
//
// RED phase: AgentController.request / on / bus do not exist yet — this
// file must fail to compile against them (undefined members), proving
// test-first order for the new surface. U2–U6 pin EXISTING bus behavior
// (unguarded on master) and are proven by deliberate mutants instead.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/events/event_bus.dart';

/// A second request/response pair — proving types dispatch independently.
class StatusRequest {
  final String key;
  StatusRequest(this.key);
}

class StatusResponse {
  final String value;
  StatusResponse(this.value);
}

void main() {
  group('spec 078 — request/response', () {
    test('controller.request round-trips a typed handler response', () async {
      final controller = AgentController();
      controller.bus.registerHandler<BeforeToolCallRequest,
          BeforeToolCallResponse>((req) async {
        return BeforeToolCallResponse({...req.args, 'approved': true},
            approved: req.toolName != 'dangerous');
      });

      final response = await controller.request<BeforeToolCallResponse>(
        BeforeToolCallRequest('web_search', {'url': 'https://x'}),
      );

      expect(response.approved, isTrue);
      expect(response.args['url'], equals('https://x'));
      expect(response.args['approved'], isTrue);
    });

    test('controller.on is an alias for listen', () {
      final controller = AgentController();
      final viaListen = <String>[];
      final viaOn = <String>[];

      controller.listen<LLMChunkEvent>((e) => viaListen.add('l:${e.chunk}'));
      controller.on<LLMChunkEvent>((e) => viaOn.add('o:${e.chunk}'));
      controller.publish(LLMChunkEvent('x'));

      expect(viaListen, ['l:x']);
      expect(viaOn, ['o:x']);
    });

    test('controller.request behaves identically to bus.request', () async {
      final bus = EventBus();
      bus.registerHandler<BeforeToolCallRequest, BeforeToolCallResponse>(
          (req) async => BeforeToolCallResponse({...req.args, 'ok': true}));
      final controller = AgentController(bus);

      final viaBus = await bus.request<BeforeToolCallResponse>(
          BeforeToolCallRequest('tool', {'n': 1}));
      final viaController =
          await controller.request<BeforeToolCallResponse>(
              BeforeToolCallRequest('tool', {'n': 1}));

      expect(viaController.args, equals(viaBus.args));
      expect(viaController.approved, equals(viaBus.approved));
    });

    test('the last registered handler responds', () async {
      final bus = EventBus();
      bus.registerHandler<BeforeToolCallRequest, BeforeToolCallResponse>(
          (req) async => BeforeToolCallResponse({'who': 'first'}));
      bus.registerHandler<BeforeToolCallRequest, BeforeToolCallResponse>(
          (req) async => BeforeToolCallResponse({'who': 'second'}));

      final response = await bus.request<BeforeToolCallResponse>(
          BeforeToolCallRequest('t', {}));

      expect(response.args['who'], equals('second'),
          reason: 'override semantics: the latest registrant wins');
    });

    test('handler exceptions propagate to the requester', () async {
      final bus = EventBus();
      bus.registerHandler<BeforeToolCallRequest, BeforeToolCallResponse>(
          (req) async => throw StateError('handler exploded'));

      await expectLater(
          bus.request<BeforeToolCallResponse>(BeforeToolCallRequest('t', {})),
          throwsA(isA<StateError>()
              .having((e) => e.message, 'message', contains('handler exploded'))));
    });

    test('request with no handler throws StateError', () {
      final bus = EventBus();
      expect(
          () => bus.request<BeforeToolCallResponse>(
              BeforeToolCallRequest('t', {})),
          throwsA(isA<StateError>().having(
              (e) => e.message, 'message', contains('BeforeToolCallRequest'))));
    });

    test('a wrong response type surfaces as a TypeError', () async {
      final bus = EventBus();
      // Handler returns a String while the requester asks for int.
      bus.registerHandler<BeforeToolCallRequest, String>(
          (req) async => 'not-a-number');

      await expectLater(
          bus.request<int>(BeforeToolCallRequest('t', {})),
          throwsA(anyOf(isA<TypeError>(), isA<TypeError>().having(
              (e) => e.toString(), 'text', contains('type')))));
    });

    test('registration is live and types dispatch independently', () async {
      final bus = EventBus();

      // Before any registration this type has no handler.
      try {
        await bus.request<StatusResponse>(StatusRequest('k'));
        fail('expected StateError before registration');
      } on StateError {
        // expected
      }

      bus.registerHandler<StatusRequest, StatusResponse>(
          (req) async => StatusResponse('status:${req.key}'));
      bus.registerHandler<BeforeToolCallRequest, BeforeToolCallResponse>(
          (req) async => BeforeToolCallResponse({'tool': true}));

      // Late registration now serves the request…
      final status = await bus.request<StatusResponse>(StatusRequest('k'));
      expect(status.value, equals('status:k'));

      // …and the other type dispatches to its own handler.
      final tool = await bus
          .request<BeforeToolCallResponse>(BeforeToolCallRequest('t', {}));
      expect(tool.args['tool'], isTrue);
    });
  });
}
