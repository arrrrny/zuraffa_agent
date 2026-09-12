// Minimal zuraffa_agent example (spec 116, issue #111).
//
// Runs a full mission end-to-end with a scripted in-process LLM client:
// no network, no API key. Watch the event bus print the mission
// lifecycle, then the final result.
//
//   dart run example/minimal_agent.dart

import 'package:zuraffa_agent/zuraffa_agent.dart';
import 'package:zuraffa_agent/src/data/providers/engine_loop/engine_loop_executor.dart';
import 'package:zuraffa_agent/src/domain/entities/engine_loop/engine_loop.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_message.dart';
import 'package:zuraffa_agent/src/domain/entities/stop_policy/stop_policy.dart';
import 'package:zuraffa_agent/src/engine/engine_event_bus.dart';
import 'package:zuraffa_agent/src/engine/events/engine_event.dart';
import 'package:zuraffa_agent/src/engine/mission_runner.dart';
import 'package:zuraffa_agent/src/engine/tool_dispatcher.dart';
import 'package:zuraffa_agent/src/llm/llm_client.dart';

import 'engine/echo_llm_client.dart';
import 'engine/noop_tool_dispatcher.dart';

Future<void> main() async {
  final loop = const EngineLoop(
    id: 'loop-example',
    sessionId: 'session-example',
    maxTurns: 10,
    wallClockTimeoutMs: 60000,
    repetitionThreshold: 5,
  );

  final bus = EngineEventBus();
  bus.subscribe<EngineEvent>((event) => print('[event] ${event.runtimeType}'));

  final runner = MissionRunner(
    executor: EngineLoopExecutor(loop, EchoLlmClient()),
    toolDispatcher: NoopToolDispatcher(),
    stopPolicy: const StopPolicy(
      id: 'example',
      maxTurns: 10,
      wallClockTimeout: Duration.zero,
      repetitionThreshold: 5,
    ),
    onEvent: bus.publish,
  );

  final result = await runner.run(
    missionId: 'demo-1',
    messages: const [
      ChatMessage(role: 'user', content: 'What is the zuraffa_agent?'),
    ],
  );

  print('---');
  print('mission   : ${result.missionId}');
  print('status    : ${result.status.name}');
  print('turns     : ${result.turnsUsed}');
  print('summary   : ${result.summary}');
}
