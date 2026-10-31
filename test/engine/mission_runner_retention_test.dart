// Issue #135 — MissionRunner between-mission retention hook.
//
// The runner invokes an injected RetentionSweep at the start of run() —
// i.e., between the previous mission and this one — before MissionStarted.
// RetentionCoordinator is the stock sweep over the durable stores.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/data/providers/engine_loop/engine_loop_executor.dart';
import 'package:zuraffa_agent/src/domain/entities/engine_loop/engine_loop.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_completion.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_message.dart';
import 'package:zuraffa_agent/src/domain/entities/stop_policy/stop_policy.dart';
import 'package:zuraffa_agent/src/domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
import 'package:zuraffa_agent/src/engine/mission_runner.dart';
import 'package:zuraffa_agent/src/engine/tool_dispatcher.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

class ScriptedLlmClient extends LlmClientProvider {
  ScriptedLlmClient(this.completions)
    : super(
        config: const ProviderConfig(
          id: 'kilo',
          providerKind: 'openai',
          baseUrl: 'https://example.invalid/v1',
          models: ['tencent/hy3:free'],
          timeoutMs: 1,
        ),
        apiKey: 'test-key',
      );

  final List<ChatCompletion> completions;
  int callCount = 0;

  @override
  Future<ChatCompletion> complete(List<ChatMessage> messages) async =>
      completions[callCount++];
}

class NoDispatch implements ToolDispatcher {
  @override
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  }) => throw StateError('no tools expected in this test');

  @override
  Future<List<ToolDispatchResult>> dispatchBatch({
    required List<ToolCall> calls,
    required bool isInternalMission,
  }) => throw StateError('no tools expected in this test');

  @override
  List<String> validateSchema({
    required Map<String, dynamic> schema,
    required Map<String, dynamic> arguments,
  }) => const [];

  @override
  bool checkRiskTier({
    required String riskTier,
    required bool isInternalMission,
  }) => true;
}

class RecordingSweep implements RetentionSweep {
  int calls = 0;
  bool sawNoEventsYet = false;

  @override
  Future<void> prune() async {
    calls++;
    sawNoEventsYet = _events.isEmpty;
  }

  final List<EngineEvent> _events;
  RecordingSweep(this._events);
}

ChatCompletion completionOf(String content) => ChatCompletion(
  content: content,
  finishReason: 'stop',
  usage: const TokenUsage(promptTokens: 1, completionTokens: 1, totalTokens: 2),
);

const loop = EngineLoop(
  id: 'loop-1',
  sessionId: 's1',
  maxTurns: 10,
  wallClockTimeoutMs: 60000,
  repetitionThreshold: 5,
);

StopPolicy policy() => const StopPolicy(
  id: 'test',
  maxTurns: 100,
  wallClockTimeout: Duration.zero,
  repetitionThreshold: 5,
);

void main() {
  final fixedNow = DateTime.utc(2026, 1, 15);
  final t0 = DateTime.utc(2026, 1, 1);
  final t1 = DateTime.utc(2026, 1, 10);

  MessageEntry entry(String id, DateTime at) =>
      MessageEntry(id: id, timestamp: at, message: UserMessage.text('m-$id'));

  MissionRunner makeRunner({
    required List<EngineEvent> events,
    RetentionSweep? retention,
  }) => MissionRunner(
    executor: EngineLoopExecutor(
      loop,
      ScriptedLlmClient([completionOf('done')]),
    ),
    toolDispatcher: NoDispatch(),
    stopPolicy: policy(),
    onEvent: events.add,
    clock: () => fixedNow,
    retention: retention,
  );

  test('the sweep runs between missions — before MissionStarted', () async {
    final events = <EngineEvent>[];
    final sweep = RecordingSweep(events);

    final runner = makeRunner(events: events, retention: sweep);
    final result = await runner.run(
      missionId: 'm1',
      messages: const [ChatMessage(role: 'user', content: 'go')],
    );

    expect(sweep.calls, 1);
    expect(
      sweep.sawNoEventsYet,
      isTrue,
      reason: 'the sweep runs before the mission lifecycle begins',
    );
    expect(events.first, isA<MissionStarted>());
    expect(result.status, MissionStatus.completed);
  });

  test('each mission run sweeps once (between missions)', () async {
    final events = <EngineEvent>[];
    final sweep = RecordingSweep(events);
    final llm = ScriptedLlmClient([completionOf('one'), completionOf('two')]);
    final runner = MissionRunner(
      executor: EngineLoopExecutor(loop, llm),
      toolDispatcher: NoDispatch(),
      stopPolicy: policy(),
      onEvent: events.add,
      clock: () => fixedNow,
      retention: sweep,
    );

    await runner.run(
      missionId: 'm1',
      messages: const [ChatMessage(role: 'user', content: 'go')],
    );
    await runner.run(
      missionId: 'm2',
      messages: const [ChatMessage(role: 'user', content: 'go')],
    );

    expect(sweep.calls, 2);
  });

  test('a runner without a sweep is unchanged', () async {
    final events = <EngineEvent>[];

    final runner = makeRunner(events: events);
    final result = await runner.run(
      missionId: 'm1',
      messages: const [ChatMessage(role: 'user', content: 'go')],
    );

    expect(result.status, MissionStatus.completed);
  });

  test(
    'RetentionCoordinator sweeps the wired stores between missions',
    () async {
      final storage = InMemorySessionStorage();
      await storage.init();
      await storage.appendEntry(entry('old', t0));
      await storage.appendEntry(entry('mid', t0.add(const Duration(days: 1))));
      await storage.appendEntry(entry('new', t1));

      UsageLedger? writtenBack;
      final coordinator = RetentionCoordinator(
        sessionStorage: storage,
        sessionPolicy: const RetentionPolicy(maxCount: 1),
        usageLedgers: [
          UsageLedgerBinding(
            ledger: () => UsageLedger([
              UsageEntry(
                id: 'u0',
                timestamp: t0,
                record: UsageLedgerEntry(
                  id: 'u0r',
                  timestamp: t0,
                  callId: 'c0',
                  turnNumber: 1,
                  inputTokens: 1,
                  outputTokens: 1,
                  cacheReadTokens: 0,
                  cacheWriteTokens: 0,
                ),
              ),
            ]),
            writeback: (ledger) => writtenBack = ledger,
            policy: const RetentionPolicy(maxCount: 0),
          ),
        ],
        clock: () => fixedNow,
      );

      final events = <EngineEvent>[];
      final runner = makeRunner(events: events, retention: coordinator);
      await runner.run(
        missionId: 'm1',
        messages: const [ChatMessage(role: 'user', content: 'go')],
      );

      expect((await storage.getEntries()).map((e) => e.id), ['new']);
      expect(writtenBack, isNotNull);
      expect(writtenBack!.isEmpty, isTrue);
    },
  );
}
