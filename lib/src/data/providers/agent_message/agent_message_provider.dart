// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#3 (R1 - state & sessions).
//
// Concrete provider for the AgentMessage data layer. Keeps the active
// mission's message log in memory: `current` returns the most recently
// appended message (or a constructed empty default when the log is empty)
// and `count` returns the log length. Mirrors the ProviderConfigProvider /
// EngineLoopProvider pattern (spec 052 / 045).

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/agent_message/agent_message.dart';
import '../../../domain/services/agent_message_service.dart';

class AgentMessageProvider
    with Loggable, FailureHandler
    implements AgentMessageService {
  /// Default message returned when the in-memory log is empty.
  static final AgentMessage empty = AgentMessage(
    id: 'empty',
    role: 'assistant',
    parts: [],
  );

  final List<AgentMessage> _messages;

  AgentMessageProvider([List<AgentMessage>? messages])
      : _messages = List<AgentMessage>.of(messages ?? const <AgentMessage>[]);

  /// Appends [message] to the in-memory log and returns it.
  AgentMessage append(AgentMessage message) {
    _messages.add(message);
    return message;
  }

  @override
  Future<AgentMessage> current(NoParams params) async =>
      _messages.isEmpty ? empty : _messages.last;

  @override
  Future<int> count(NoParams params) async => _messages.length;
}
