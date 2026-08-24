// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#3 (R1 - state & sessions).
//
// Concrete provider stub for the AgentMessage data layer. Mirrors the
// SteeringQueueProvider pattern (spec 033) and ToolResultProvider
// (spec 031): bodies throw UnimplementedError so the file is analyzable
// without forcing real I/O.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/agent_message/agent_message.dart';
import '../../../domain/services/agent_message_service.dart';

class AgentMessageProvider
    with Loggable, FailureHandler
    implements AgentMessageService {
  AgentMessageProvider();

  @override
  Future<AgentMessage> current(NoParams params) async =>
      throw UnimplementedError('Implement AgentMessageProvider.current');

  @override
  Future<int> count(NoParams params) async =>
      throw UnimplementedError('Implement AgentMessageProvider.count');
}
