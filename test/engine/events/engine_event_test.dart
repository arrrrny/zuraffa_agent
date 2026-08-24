import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;

import 'package:zuraffa_agent/src/engine/events/engine_event.dart';

void main() {
  group('arrarrny/zuraffa_agent#24 — sealed EngineEvent library', () {
    final fixedTime = DateTime.utc(2026, 8, 24, 7, 30, 0);

    test('TurnStarted is an EngineEvent', () {
      final event = TurnStarted(emittedAt: fixedTime);
      expect(event, isA<EngineEvent>());
    });

    test('TurnStarted carries emittedAt + optional turnId', () {
      final event = TurnStarted(emittedAt: fixedTime, turnId: 't-42');
      expect(event.emittedAt, fixedTime);
      expect(event.turnId, 't-42');
    });

    test('TurnStarted.turnId defaults to null for ephemeral turns', () {
      final event = TurnStarted(emittedAt: fixedTime);
      expect(event.turnId, isNull);
    });

    test('switch over EngineEvent is exhaustive with all current subtypes', () {
      String describe(EngineEvent e) => switch (e) {
        TurnStarted(:final turnId) => 'turn_started($turnId)',
        TurnCompleted(:final reason) => 'turn_completed($reason)',
        ToolCallStarted(:final toolName) => 'tool_call_started($toolName)',
        ToolCallCompleted(:final toolName) => 'tool_call_completed($toolName)',
      };

      final startEvent = TurnStarted(emittedAt: fixedTime, turnId: 't-1');
      final completeEvent = TurnCompleted(emittedAt: fixedTime);
      final toolStartEvent = ToolCallStarted(
        emittedAt: fixedTime,
        toolName: 'webview.browse',
        callId: 'c-1',
      );
      expect(describe(startEvent), 'turn_started(t-1)');
      expect(describe(completeEvent), 'turn_completed(null)');
      expect(describe(toolStartEvent), 'tool_call_started(webview.browse)');
    });

    test('NoParams is reachable (smoke)', () {
      expect(NoParams(), isA<NoParams>());
    });
  });

  group('arrarrny/zuraffa_agent#23 — EngineEvent.TurnCompleted', () {
    final fixedTime = DateTime.utc(2026, 8, 24, 7, 31, 0);

    test('TurnCompleted is an EngineEvent', () {
      final event = TurnCompleted(emittedAt: fixedTime);
      expect(event, isA<EngineEvent>());
      expect(event, isA<TurnCompleted>());
    });

    test('TurnCompleted carries emittedAt + optional reason', () {
      final event = TurnCompleted(emittedAt: fixedTime, reason: 'cancelled');
      expect(event.emittedAt, fixedTime);
      expect(event.reason, 'cancelled');
    });

    test('TurnCompleted.reason defaults to null on normal completion', () {
      final event = TurnCompleted(emittedAt: fixedTime);
      expect(event.reason, isNull);
    });
  });

  group('arrarrny/zuraffa_agent#22 — EngineEvent.ToolCallStarted', () {
    final fixedTime = DateTime.utc(2026, 8, 24, 7, 32, 0);

    test('ToolCallStarted is an EngineEvent', () {
      final event = ToolCallStarted(
        emittedAt: fixedTime,
        toolName: 'webview.browse',
        callId: 'c-1',
      );
      expect(event, isA<EngineEvent>());
      expect(event, isA<ToolCallStarted>());
    });

    test('ToolCallStarted carries emittedAt, toolName, callId', () {
      final event = ToolCallStarted(
        emittedAt: fixedTime,
        toolName: 'fs.read',
        callId: 'c-2',
      );
      expect(event.emittedAt, fixedTime);
      expect(event.toolName, 'fs.read');
      expect(event.callId, 'c-2');
    });
  });
  group('arrarrny/zuraffa_agent#21 — EngineEvent.ToolCallCompleted', () {
    final fixedTime = DateTime.utc(2026, 8, 24, 8, 0, 0);

    test('ToolCallCompleted is an EngineEvent', () {
      final event = ToolCallCompleted(emittedAt: fixedTime, toolName: 'sample', callId: 'sample', ok: true);
      expect(event, isA<EngineEvent>());
      expect(event, isA<ToolCallCompleted>());
    });

    test('ToolCallCompleted carries payload fields', () {
      final event = ToolCallCompleted(emittedAt: fixedTime, toolName: 'sample', callId: 'sample', ok: true);
      expect(event.emittedAt, fixedTime);
      expect(event.toolName, 'sample');
      expect(event.callId, 'sample');
      expect(event.ok, isTrue);
    });  });
}
