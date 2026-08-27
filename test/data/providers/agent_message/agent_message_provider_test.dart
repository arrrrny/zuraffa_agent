// HAND-CURATED regression tests for the AgentMessage value object +
// AgentMessageProvider. Pattern mirrors spec 033.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/domain/entities/agent_message/agent_message.dart';
import 'package:zuraffa_agent/src/domain/services/agent_message_service.dart';
import 'package:zuraffa_agent/src/data/providers/agent_message/agent_message_provider.dart';

void main() {
  group('arrarrny/zuraffa_agent#3 - AgentMessage value equality', () {
    test('AgentMessage equality is value-based across all fields', () {
      final a = AgentMessage(id: 'id-a', role: 'assistant', parts: const ['text']);
      final b = AgentMessage(id: 'id-a', role: 'assistant', parts: const ['text']);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('AgentMessage inequality differs when a field changes', () {
      final a = AgentMessage(id: 'id-a', role: 'assistant', parts: const ['text']);
      final b = AgentMessage(id: 'id-b', role: 'assistant', parts: const ['text','img']);
      expect(a == b, isFalse);
    });
  });

  group('arrarrny/zuraffa_agent#3 - AgentMessage clean-arch layers', () {
    test('AgentMessageProvider is a AgentMessageService', () {
      final provider = AgentMessageProvider();
      expect(provider, isA<AgentMessageService>());
    });

    test('AgentMessageProvider.current returns an empty default when the log is empty', () async {
      final message = await AgentMessageProvider().current(NoParams());
      expect(message, isA<AgentMessage>());
      expect(message.parts, isEmpty);
      expect(message.role, isNotEmpty);
    });

    test('AgentMessageProvider.count returns 0 for an empty log', () async {
      expect(await AgentMessageProvider().count(NoParams()), 0);
    });

    test('AgentMessageProvider.current returns the most recently appended message', () async {
      final provider = AgentMessageProvider();
      provider.append(AgentMessage(id: 'm-1', role: 'user', parts: const ['hi']));
      final latest = AgentMessage(id: 'm-2', role: 'assistant', parts: const ['yo']);
      provider.append(latest);
      expect(await provider.current(NoParams()), equals(latest));
      expect(await provider.count(NoParams()), 2);
    });

    test('AgentMessageProvider accepts a seeded message log', () async {
      final seeded = AgentMessage(id: 'm-9', role: 'user', parts: const ['seed']);
      final provider = AgentMessageProvider([seeded]);
      expect(await provider.current(NoParams()), equals(seeded));
      expect(await provider.count(NoParams()), 1);
    });
  });
}
