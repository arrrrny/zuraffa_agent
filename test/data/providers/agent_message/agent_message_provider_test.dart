// HAND-CURATED regression tests for the AgentMessage value object +
// AgentMessageProvider stub. Pattern mirrors spec 033.

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

    test('AgentMessageProvider.current throws UnimplementedError on NoParams', () {
      final provider = AgentMessageProvider();
      expect(
        () => provider.current(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('AgentMessageProvider.count throws UnimplementedError on NoParams', () {
      final provider = AgentMessageProvider();
      expect(
        () => provider.count(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
