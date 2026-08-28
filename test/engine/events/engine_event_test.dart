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
        ThinkingDelta(:final delta) => 'thinking_delta($delta)',
        SteeringInjected(:final content) => 'steering_injected($content)',
        ProviderError(:final providerName) => 'provider_error($providerName)',
        MissionStarted(:final missionId) => 'mission_started($missionId)',
        MissionCompleted(:final missionId) => 'mission_completed($missionId)',
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
  group('arrarrny/zuraffa_agent#20 — EngineEvent.ThinkingDelta', () {
    final fixedTime = DateTime.utc(2026, 8, 24, 8, 0, 0);

    test('ThinkingDelta is an EngineEvent', () {
      final event = ThinkingDelta(emittedAt: fixedTime, delta: 'sample');
      expect(event, isA<EngineEvent>());
      expect(event, isA<ThinkingDelta>());
    });

    test('ThinkingDelta carries payload fields', () {
      final event = ThinkingDelta(emittedAt: fixedTime, delta: 'sample');
      expect(event.emittedAt, fixedTime);
      expect(event.delta, 'sample');
    });  });
  group('arrarrny/zuraffa_agent#19 — EngineEvent.SteeringInjected', () {
    final fixedTime = DateTime.utc(2026, 8, 24, 8, 0, 0);

    test('SteeringInjected is an EngineEvent', () {
      final event = SteeringInjected(emittedAt: fixedTime, content: 'sample', injectedAt: fixedTime);
      expect(event, isA<EngineEvent>());
      expect(event, isA<SteeringInjected>());
    });

    test('SteeringInjected carries payload fields', () {
      final event = SteeringInjected(emittedAt: fixedTime, content: 'sample', injectedAt: fixedTime);
      expect(event.emittedAt, fixedTime);
      expect(event.content, 'sample');
      expect(event.injectedAt, fixedTime);
    });  });
  group('arrarrny/zuraffa_agent#18 — EngineEvent.ProviderError', () {
    final fixedTime = DateTime.utc(2026, 8, 24, 8, 0, 0);

    test('ProviderError is an EngineEvent', () {
      final event = ProviderError(emittedAt: fixedTime, providerName: 'sample', error: 'sample');
      expect(event, isA<EngineEvent>());
      expect(event, isA<ProviderError>());
    });

    test('ProviderError carries payload fields', () {
      final event = ProviderError(
        emittedAt: fixedTime,
        providerName: 'openai',
        error: '401 unauthorized (terminal)',
      );
      expect(event.emittedAt, fixedTime);
      expect(event.providerName, 'openai');
      expect(event.error, '401 unauthorized (terminal)');
    });

    test('describe(EngineEvent) switch routes ProviderError to provider_error(providerName)', () {
      String describe(EngineEvent e) => switch (e) {
        TurnStarted(:final turnId) => 'turn_started($turnId)',
        TurnCompleted(:final reason) => 'turn_completed($reason)',
        ToolCallStarted(:final toolName) => 'tool_call_started($toolName)',
        ToolCallCompleted(:final toolName) => 'tool_call_completed($toolName)',
        ThinkingDelta(:final delta) => 'thinking_delta($delta)',
        SteeringInjected(:final content) => 'steering_injected($content)',
        ProviderError(:final providerName) => 'provider_error($providerName)',
        MissionStarted(:final missionId) => 'mission_started($missionId)',
        MissionCompleted(:final missionId) => 'mission_completed($missionId)',
      };

      final event = ProviderError(
        emittedAt: fixedTime,
        providerName: 'openai',
        error: '401 unauthorized (terminal)',
      );
      expect(describe(event), 'provider_error(openai)');
    });
  });
  group('arrarrny/zuraffa_agent#17 — EngineEvent.MissionStarted', () {
    final fixedTime = DateTime.utc(2026, 8, 24, 8, 0, 0);
    final startedTime = DateTime.utc(2026, 8, 24, 7, 45, 0);

    test('MissionStarted is an EngineEvent', () {
      final event = MissionStarted(emittedAt: fixedTime, missionId: 'sample', startedAt: fixedTime);
      expect(event, isA<EngineEvent>());
      expect(event, isA<MissionStarted>());
    });

    test('MissionStarted carries payload fields', () {
      final event = MissionStarted(emittedAt: fixedTime, missionId: 'm-7', startedAt: startedTime);
      expect(event.emittedAt, fixedTime);
      expect(event.missionId, 'm-7');
      expect(event.startedAt, startedTime);
      expect(event.startedAt, isNot(equals(event.emittedAt)));
    });

    test('describe(EngineEvent) switch routes MissionStarted to mission_started(missionId)', () {
      String describe(EngineEvent e) => switch (e) {
        TurnStarted(:final turnId) => 'turn_started($turnId)',
        TurnCompleted(:final reason) => 'turn_completed($reason)',
        ToolCallStarted(:final toolName) => 'tool_call_started($toolName)',
        ToolCallCompleted(:final toolName) => 'tool_call_completed($toolName)',
        ThinkingDelta(:final delta) => 'thinking_delta($delta)',
        SteeringInjected(:final content) => 'steering_injected($content)',
        ProviderError(:final providerName) => 'provider_error($providerName)',
        MissionStarted(:final missionId) => 'mission_started($missionId)',
        MissionCompleted(:final missionId) => 'mission_completed($missionId)',
      };

      final event = MissionStarted(emittedAt: fixedTime, missionId: 'm-7', startedAt: startedTime);
      expect(describe(event), 'mission_started(m-7)');
    });
  });
  group('arrarrny/zuraffa_agent#16 — EngineEvent.MissionCompleted', () {
    final fixedTime = DateTime.utc(2026, 8, 24, 8, 0, 0);

    test('MissionCompleted is an EngineEvent', () {
      final event = MissionCompleted(emittedAt: fixedTime, missionId: 'sample', status: 'sample', summary: null);
      expect(event, isA<EngineEvent>());
      expect(event, isA<MissionCompleted>());
    });

    test('MissionCompleted carries payload fields', () {
      final event = MissionCompleted(
        emittedAt: fixedTime,
        missionId: 'm-42',
        status: 'success',
        summary: 'all goals met',
      );
      expect(event.emittedAt, fixedTime);
      expect(event.missionId, 'm-42');
      expect(event.status, 'success');
      expect(event.summary, 'all goals met');
    });

    test('MissionCompleted.summary is nullable and round-trips null', () {
      final event = MissionCompleted(
        emittedAt: fixedTime,
        missionId: 'm-42',
        status: 'cancelled',
        summary: null,
      );
      expect(event.summary, isNull);
    });

    test('describe(EngineEvent) switch routes MissionCompleted to mission_completed(missionId)', () {
      String describe(EngineEvent e) => switch (e) {
        TurnStarted(:final turnId) => 'turn_started($turnId)',
        TurnCompleted(:final reason) => 'turn_completed($reason)',
        ToolCallStarted(:final toolName) => 'tool_call_started($toolName)',
        ToolCallCompleted(:final toolName) => 'tool_call_completed($toolName)',
        ThinkingDelta(:final delta) => 'thinking_delta($delta)',
        SteeringInjected(:final content) => 'steering_injected($content)',
        ProviderError(:final providerName) => 'provider_error($providerName)',
        MissionStarted(:final missionId) => 'mission_started($missionId)',
        MissionCompleted(:final missionId) => 'mission_completed($missionId)',
      };

      final event = MissionCompleted(
        emittedAt: fixedTime,
        missionId: 'm-42',
        status: 'fail',
        summary: 'goal 2 unreachable',
      );
      expect(describe(event), 'mission_completed(m-42)');
    });
  });

  group('spec 066 — EngineEvent value semantics', () {
    final t = DateTime.utc(2026, 8, 24, 7, 30, 0);
    final otherTime = DateTime.utc(2026, 8, 24, 9, 15, 0);

    test('TurnStarted equality, hashCode, toString', () {
      final a = TurnStarted(emittedAt: t, turnId: 't-1');
      final b = TurnStarted(emittedAt: t, turnId: 't-1');
      expect(a, equals(b));
      expect(b, equals(a));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(TurnStarted(emittedAt: t, turnId: 't-2'))));
      expect(a, isNot(equals(TurnStarted(emittedAt: t))));
      expect(a, isNot(equals(TurnStarted(emittedAt: otherTime, turnId: 't-1'))));
      expect(a.toString(), 'TurnStarted(emittedAt: 2026-08-24 07:30:00.000Z, turnId: t-1)');
      expect(TurnStarted(emittedAt: t).toString(), 'TurnStarted(emittedAt: 2026-08-24 07:30:00.000Z, turnId: null)');
    });

    test('TurnCompleted equality, hashCode, toString', () {
      final a = TurnCompleted(emittedAt: t, reason: 'cancelled');
      final b = TurnCompleted(emittedAt: t, reason: 'cancelled');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(TurnCompleted(emittedAt: t, reason: 'max-tokens-reached'))));
      expect(a, isNot(equals(TurnCompleted(emittedAt: t))));
      expect(a, isNot(equals(TurnCompleted(emittedAt: otherTime, reason: 'cancelled'))));
      expect(a.toString(), 'TurnCompleted(emittedAt: 2026-08-24 07:30:00.000Z, reason: cancelled)');
      expect(TurnCompleted(emittedAt: t).toString(), 'TurnCompleted(emittedAt: 2026-08-24 07:30:00.000Z, reason: null)');
    });

    test('ToolCallStarted equality, hashCode, toString', () {
      final a = ToolCallStarted(emittedAt: t, toolName: 'fs.read', callId: 'c-1');
      final b = ToolCallStarted(emittedAt: t, toolName: 'fs.read', callId: 'c-1');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(ToolCallStarted(emittedAt: t, toolName: 'fs.write', callId: 'c-1'))));
      expect(a, isNot(equals(ToolCallStarted(emittedAt: t, toolName: 'fs.read', callId: 'c-2'))));
      expect(a, isNot(equals(ToolCallStarted(emittedAt: otherTime, toolName: 'fs.read', callId: 'c-1'))));
      expect(a.toString(), 'ToolCallStarted(emittedAt: 2026-08-24 07:30:00.000Z, toolName: fs.read, callId: c-1)');
    });

    test('ToolCallCompleted equality, hashCode, toString', () {
      final a = ToolCallCompleted(emittedAt: t, toolName: 'fs.read', callId: 'c-1', ok: true);
      final b = ToolCallCompleted(emittedAt: t, toolName: 'fs.read', callId: 'c-1', ok: true);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(ToolCallCompleted(emittedAt: t, toolName: 'fs.read', callId: 'c-1', ok: false))));
      expect(a, isNot(equals(ToolCallCompleted(emittedAt: t, toolName: 'fs.write', callId: 'c-1', ok: true))));
      expect(a, isNot(equals(ToolCallCompleted(emittedAt: t, toolName: 'fs.read', callId: 'c-2', ok: true))));
      expect(a, isNot(equals(ToolCallCompleted(emittedAt: otherTime, toolName: 'fs.read', callId: 'c-1', ok: true))));
      expect(a.toString(), 'ToolCallCompleted(emittedAt: 2026-08-24 07:30:00.000Z, toolName: fs.read, callId: c-1, ok: true)');
    });

    test('ThinkingDelta equality, hashCode, toString', () {
      final a = ThinkingDelta(emittedAt: t, delta: 'thinking...');
      final b = ThinkingDelta(emittedAt: t, delta: 'thinking...');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(ThinkingDelta(emittedAt: t, delta: 'other'))));
      expect(a, isNot(equals(ThinkingDelta(emittedAt: otherTime, delta: 'thinking...'))));
      expect(a.toString(), 'ThinkingDelta(emittedAt: 2026-08-24 07:30:00.000Z, delta: thinking...)');
    });

    test('SteeringInjected equality, hashCode, toString', () {
      final a = SteeringInjected(emittedAt: t, content: 'new direction', injectedAt: otherTime);
      final b = SteeringInjected(emittedAt: t, content: 'new direction', injectedAt: otherTime);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(SteeringInjected(emittedAt: t, content: 'other direction', injectedAt: otherTime))));
      expect(a, isNot(equals(SteeringInjected(emittedAt: t, content: 'new direction', injectedAt: t))));
      expect(a, isNot(equals(SteeringInjected(emittedAt: otherTime, content: 'new direction', injectedAt: otherTime))));
      expect(
        a.toString(),
        'SteeringInjected(emittedAt: 2026-08-24 07:30:00.000Z, content: new direction, injectedAt: 2026-08-24 09:15:00.000Z)',
      );
    });

    test('ProviderError equality, hashCode, toString', () {
      final a = ProviderError(emittedAt: t, providerName: 'openai', error: '401 unauthorized');
      final b = ProviderError(emittedAt: t, providerName: 'openai', error: '401 unauthorized');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(ProviderError(emittedAt: t, providerName: 'anthropic', error: '401 unauthorized'))));
      expect(a, isNot(equals(ProviderError(emittedAt: t, providerName: 'openai', error: '429 rate-limited'))));
      expect(a, isNot(equals(ProviderError(emittedAt: otherTime, providerName: 'openai', error: '401 unauthorized'))));
      expect(a.toString(), 'ProviderError(emittedAt: 2026-08-24 07:30:00.000Z, providerName: openai, error: 401 unauthorized)');
    });

    test('MissionStarted equality, hashCode, toString', () {
      final a = MissionStarted(emittedAt: t, missionId: 'm-7', startedAt: otherTime);
      final b = MissionStarted(emittedAt: t, missionId: 'm-7', startedAt: otherTime);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(MissionStarted(emittedAt: t, missionId: 'm-8', startedAt: otherTime))));
      expect(a, isNot(equals(MissionStarted(emittedAt: t, missionId: 'm-7', startedAt: t))));
      expect(a, isNot(equals(MissionStarted(emittedAt: otherTime, missionId: 'm-7', startedAt: otherTime))));
      expect(
        a.toString(),
        'MissionStarted(emittedAt: 2026-08-24 07:30:00.000Z, missionId: m-7, startedAt: 2026-08-24 09:15:00.000Z)',
      );
    });

    test('MissionCompleted equality, hashCode, toString', () {
      final a = MissionCompleted(emittedAt: t, missionId: 'm-7', status: 'success', summary: 'all goals met');
      final b = MissionCompleted(emittedAt: t, missionId: 'm-7', status: 'success', summary: 'all goals met');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(MissionCompleted(emittedAt: t, missionId: 'm-8', status: 'success', summary: 'all goals met'))));
      expect(a, isNot(equals(MissionCompleted(emittedAt: t, missionId: 'm-7', status: 'fail', summary: 'all goals met'))));
      expect(a, isNot(equals(MissionCompleted(emittedAt: t, missionId: 'm-7', status: 'success', summary: null))));
      expect(a, isNot(equals(MissionCompleted(emittedAt: otherTime, missionId: 'm-7', status: 'success', summary: 'all goals met'))));
      expect(
        a.toString(),
        'MissionCompleted(emittedAt: 2026-08-24 07:30:00.000Z, missionId: m-7, status: success, summary: all goals met)',
      );
      expect(
        MissionCompleted(emittedAt: t, missionId: 'm-7', status: 'cancelled', summary: null).toString(),
        'MissionCompleted(emittedAt: 2026-08-24 07:30:00.000Z, missionId: m-7, status: cancelled, summary: null)',
      );
    });

    test('different runtimeTypes are never equal', () {
      // TurnStarted and TurnCompleted share the same field shape
      // (DateTime + String?); only the runtimeType guard separates them.
      final started = TurnStarted(emittedAt: t, turnId: 'same');
      final completed = TurnCompleted(emittedAt: t, reason: 'same');
      expect(started == completed, isFalse);
      expect(completed == started, isFalse);

    });
  });
}
