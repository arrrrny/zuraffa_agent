// Spec 117 (issue arrrrny/zuraffa_agent#190) — LlmToolLoop.
//
// The lean, generic function-calling runtime over the typed seam
// (LlmClient + AgentMessage). Behaviors (specs/117-llm-tool-loop/):
// - drives generate() → execute tools → append results → repeat until a
//   stop response;
// - budget + max-call enforcement (honest failure, never silent truncation);
// - per-tool-result middleware plug-in point (PII scrubber is consumer #1);
// - barrel-exported: a downstream consumer builds on package:zuraffa_agent
//   exports alone.

import 'package:test/test.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

import 'fake_llm_client.dart';

ToolResultMessage _toolResult(String id, String content) =>
    ToolResultMessage(toolCallId: id, toolName: 'lookup', content: content);

void main() {
  group('spec 117 — LlmToolLoop drives the FC loop (barrel surface)', () {
    test('the loop type is reachable from the package barrel', () {
      // A compile-time proof that `LlmToolLoop` is a barrel export: a
      // downstream consumer names it with only package:zuraffa_agent
      // imported (llm_client.dart / types.dart are also barrel exports).
      LlmToolLoop make(LlmClient client) =>
          LlmToolLoop(client, (call) async => _toolResult(call.id, 'r'));
      expect(make, isNotNull);
    });

    test(
      'executes tool calls and returns the terminal assistant message',
      () async {
        final client = FakeLlmClient(
          providerName: 'fake',
          outcomes: [
            const ScriptedOutcome(
              response: LlmResponse(
                content: 'calling',
                toolCalls: [
                  LlmToolCall(id: 'c1', name: 'lookup', arguments: {'q': 'x'}),
                ],
                finishReason: 'tool_calls',
              ),
            ),
            const ScriptedOutcome(
              response: LlmResponse(content: 'done', finishReason: 'stop'),
            ),
          ],
        );

        final loop = LlmToolLoop(
          client,
          (call) async => ToolResultMessage(
            toolCallId: call.id,
            toolName: call.name,
            content: 'result-for-${call.arguments['q']}',
          ),
        );

        final result = await loop.run([UserMessage.text('hi')]);

        expect(result.finished, isTrue);
        // The loop records every call it dispatched; the executor above runs
        // inline, so the result is the only place the executed call shows up.
        expect(result.toolCalls.map((c) => c.id), ['c1']);
        expect(client.generateCalls, 2);
        // Two messages were appended to the request on the second turn:
        // the assistant tool-call turn + the tool result.
        final secondRequest = client.requests[1];
        expect(secondRequest.messages, hasLength(3));
        expect(secondRequest.messages[1], isA<AssistantMessage>());
        expect(secondRequest.messages[2], isA<ToolResultMessage>());
        final toolMsg = secondRequest.messages[2] as ToolResultMessage;
        expect(toolMsg.content, 'result-for-x');
        expect(toolMsg.toolCallId, 'c1');
        // The returned message is the model's terminal text turn.
        expect(result.messages.last, isA<AssistantMessage>());
        final last = result.messages.last as AssistantMessage;
        expect(last.content.first, isA<TextBlock>());
        expect((last.content.first as TextBlock).text, 'done');
      },
    );

    test('records every executed call for caller observability', () async {
      final client = FakeLlmClient(
        providerName: 'fake',
        outcomes: [
          const ScriptedOutcome(
            response: LlmResponse(
              toolCalls: [
                LlmToolCall(id: 'a', name: 't', arguments: {}),
                LlmToolCall(id: 'b', name: 't', arguments: {}),
              ],
              finishReason: 'tool_calls',
            ),
          ),
          const ScriptedOutcome(
            response: LlmResponse(content: 'ok', finishReason: 'stop'),
          ),
        ],
      );
      final loop = LlmToolLoop(
        client,
        (call) async => ToolResultMessage(
          toolCallId: call.id,
          toolName: call.name,
          content: 'r',
        ),
      );
      final result = await loop.run([UserMessage.text('go')]);
      expect(result.toolCalls.map((c) => c.id), ['a', 'b']);
    });

    test('maxToolCalls budget fails honestly (no silent truncation)', () async {
      // The model never stops asking for tools — an infinite script would
      // hang; the budget is what stops it.
      final client = FakeLlmClient(
        providerName: 'fake',
        outcomes: List.generate(
          10,
          (_) => const ScriptedOutcome(
            response: LlmResponse(
              toolCalls: [LlmToolCall(id: 'x', name: 'loop', arguments: {})],
              finishReason: 'tool_calls',
            ),
          ),
        ),
      );
      final loop = LlmToolLoop(
        client,
        (call) async => ToolResultMessage(
          toolCallId: call.id,
          toolName: call.name,
          content: 'r',
        ),
        maxToolCalls: 3,
      );

      final result = await loop.run([UserMessage.text('go')]);

      expect(result.finished, isFalse);
      expect(result.failure, isA<ToolLoopBudgetExceeded>());
      expect(result.toolCalls, hasLength(3));
      final failure = result.failure! as ToolLoopBudgetExceeded;
      expect(failure.executed, 3);
      expect(failure.limit, 3);
    });

    test(
      'a budget stop mid-batch leaves no dangling tool_use blocks',
      () async {
        // The model asks for three calls at once and the budget allows two:
        // the third call never runs, so its `tool_use` block must not stay in
        // the transcript without a matching `tool_result`.
        final client = FakeLlmClient(
          providerName: 'fake',
          outcomes: const [
            ScriptedOutcome(
              response: LlmResponse(
                toolCalls: [
                  LlmToolCall(id: 'c1', name: 't', arguments: {}),
                  LlmToolCall(id: 'c2', name: 't', arguments: {}),
                  LlmToolCall(id: 'c3', name: 't', arguments: {}),
                ],
                finishReason: 'tool_calls',
              ),
            ),
          ],
        );
        final loop = LlmToolLoop(
          client,
          (call) async => ToolResultMessage(
            toolCallId: call.id,
            toolName: call.name,
            content: 'r',
          ),
          maxToolCalls: 2,
        );

        final result = await loop.run([UserMessage.text('go')]);

        expect(result.finished, isFalse);
        expect(result.failure, isA<ToolLoopBudgetExceeded>());
        expect(result.toolCalls.map((c) => c.id), ['c1', 'c2']);

        final transcript = result.failure!.messages;
        final assistant = transcript.whereType<AssistantMessage>().single;
        final toolCallIds = assistant.content
            .whereType<ToolCallBlock>()
            .map((b) => b.id)
            .toList();
        final toolResultIds = transcript
            .whereType<ToolResultMessage>()
            .map((m) => m.toolCallId)
            .toList();
        expect(toolCallIds, ['c1', 'c2']);
        // Every `tool_use` in the transcript has its `tool_result`.
        expect(toolResultIds, toolCallIds);
      },
    );

    test(
      'a middleware that throws becomes an error result, not a crash',
      () async {
        // The PII scrubber is consumer #1; a transform that throws must be
        // contained the way a throwing executor is, or it escapes run() as a
        // raw exception and the tool_use block loses its result.
        final client = FakeLlmClient(
          providerName: 'fake',
          outcomes: [
            const ScriptedOutcome(
              response: LlmResponse(
                toolCalls: [
                  LlmToolCall(id: 'c1', name: 'lookup', arguments: {}),
                ],
                finishReason: 'tool_calls',
              ),
            ),
            const ScriptedOutcome(
              response: LlmResponse(content: 'done', finishReason: 'stop'),
            ),
          ],
        );
        final loop = LlmToolLoop(
          client,
          (call) async => ToolResultMessage(
            toolCallId: call.id,
            toolName: call.name,
            content: 'SSN 123-45-6789',
          ),
          middleware: [(result) => throw StateError('scrubber exploded')],
        );

        final result = await loop.run([UserMessage.text('go')]);

        expect(result.finished, isTrue);
        final toolMsg = client.requests[1].messages[2] as ToolResultMessage;
        expect(toolMsg.isError, isTrue);
        expect(toolMsg.content, contains('scrubber exploded'));
        expect(toolMsg.toolCallId, 'c1');
        // The scrubber's output is dropped, not passed through unscrubbed.
        expect(toolMsg.content, isNot(contains('123-45-6789')));
      },
    );

    test('turn budget fails honestly', () async {
      final client = FakeLlmClient(
        providerName: 'fake',
        outcomes: List.generate(
          10,
          (_) => const ScriptedOutcome(
            response: LlmResponse(
              toolCalls: [LlmToolCall(id: 'x', name: 'loop', arguments: {})],
              finishReason: 'tool_calls',
            ),
          ),
        ),
      );
      final loop = LlmToolLoop(
        client,
        (call) async => ToolResultMessage(
          toolCallId: call.id,
          toolName: call.name,
          content: 'r',
        ),
        maxTurns: 2,
      );

      final result = await loop.run([UserMessage.text('go')]);

      expect(result.finished, isFalse);
      expect(result.failure, isA<ToolLoopTurnBudgetExceeded>());
      // maxTurns=2 → generate called exactly twice.
      expect(client.generateCalls, 2);
    });

    test('a provider error surfaces as an honest failure', () async {
      final client = FakeLlmClient(
        providerName: 'fake',
        outcomes: const [
          ScriptedOutcome(
            error: LlmNetworkException(provider: 'fake', cause: 'boom'),
          ),
        ],
      );
      final loop = LlmToolLoop(
        client,
        (call) async => ToolResultMessage(
          toolCallId: call.id,
          toolName: call.name,
          content: 'r',
        ),
      );

      final result = await loop.run([UserMessage.text('go')]);

      expect(result.finished, isFalse);
      expect(result.failure, isA<ToolLoopProviderError>());
      expect(
        (result.failure! as ToolLoopProviderError).cause,
        isA<LlmNetworkException>(),
      );
    });

    test(
      'middleware transforms each tool result before it enters the transcript',
      () async {
        final client = FakeLlmClient(
          providerName: 'fake',
          outcomes: [
            const ScriptedOutcome(
              response: LlmResponse(
                toolCalls: [
                  LlmToolCall(id: 'c1', name: 'lookup', arguments: {}),
                ],
                finishReason: 'tool_calls',
              ),
            ),
            const ScriptedOutcome(
              response: LlmResponse(content: 'done', finishReason: 'stop'),
            ),
          ],
        );
        final seen = <String>[];
        final loop = LlmToolLoop(
          client,
          (call) async => ToolResultMessage(
            toolCallId: call.id,
            toolName: call.name,
            content: 'SSN 123-45-6789',
          ),
          middleware: [
            (result) {
              seen.add(result.content);
              return ToolResultMessage(
                toolCallId: result.toolCallId,
                toolName: result.toolName,
                content: result.content.replaceAll('123-45-6789', '[redacted]'),
                isError: result.isError,
              );
            },
          ],
        );

        await loop.run([UserMessage.text('go')]);

        expect(seen, ['SSN 123-45-6789']);
        final toolMsg = client.requests[1].messages[2] as ToolResultMessage;
        expect(toolMsg.content, 'SSN [redacted]');
      },
    );

    test(
      'a tool that throws becomes an error tool result, not a crash',
      () async {
        final client = FakeLlmClient(
          providerName: 'fake',
          outcomes: [
            const ScriptedOutcome(
              response: LlmResponse(
                toolCalls: [LlmToolCall(id: 'c1', name: 'boom', arguments: {})],
                finishReason: 'tool_calls',
              ),
            ),
            const ScriptedOutcome(
              response: LlmResponse(content: 'recovered', finishReason: 'stop'),
            ),
          ],
        );
        final loop = LlmToolLoop(
          client,
          (call) async => throw StateError('tool exploded'),
        );

        final result = await loop.run([UserMessage.text('go')]);

        expect(result.finished, isTrue);
        final toolMsg = client.requests[1].messages[2] as ToolResultMessage;
        expect(toolMsg.isError, isTrue);
        expect(toolMsg.content, contains('tool exploded'));
      },
    );

    test(
      'empty tool calls with a non-stop finish still continues the loop',
      () async {
        // finishReason 'length' with no tool calls must NOT be read as a
        // natural stop — the model was cut off, so the loop continues.
        final client = FakeLlmClient(
          providerName: 'fake',
          outcomes: [
            const ScriptedOutcome(
              response: LlmResponse(content: 'partial', finishReason: 'length'),
            ),
            const ScriptedOutcome(
              response: LlmResponse(content: 'final', finishReason: 'stop'),
            ),
          ],
        );
        final loop = LlmToolLoop(
          client,
          (call) async => _toolResult(call.id, 'r'),
        );

        final result = await loop.run([UserMessage.text('go')]);

        expect(client.generateCalls, 2);
        expect(result.finished, isTrue);
      },
    );

    test('a config snapshot drives the loop and is reported back', () async {
      final client = FakeLlmClient(
        providerName: 'fake',
        outcomes: const [
          ScriptedOutcome(
            response: LlmResponse(content: 'hi', finishReason: 'stop'),
          ),
        ],
      );
      const config = ToolLoopConfig(
        maxToolCalls: 5,
        maxTurns: 4,
        systemPrompt: 'you are a helper',
      );
      final loop = LlmToolLoop(
        client,
        (call) async => _toolResult(call.id, 'r'),
        config: config,
      );

      final result = await loop.run([UserMessage.text('go')]);

      expect(result.config.maxToolCalls, 5);
      expect(client.requests.single.systemPrompt, 'you are a helper');
      expect(client.requests.single.tools, isNull);
    });

    test('advertised tools ride the request', () async {
      final client = FakeLlmClient(
        providerName: 'fake',
        outcomes: const [
          ScriptedOutcome(
            response: LlmResponse(content: 'hi', finishReason: 'stop'),
          ),
        ],
      );
      final loop = LlmToolLoop(
        client,
        (call) async => _toolResult(call.id, 'r'),
        config: const ToolLoopConfig(
          tools: [
            LlmToolSpec(name: 'lookup', description: 'look up', parameters: {}),
          ],
        ),
      );

      await loop.run([UserMessage.text('go')]);

      expect(client.requests.single.tools, hasLength(1));
      expect(client.requests.single.tools!.single.name, 'lookup');
    });

    test('_toolResult helper compiles against the typed family', () {
      // sanity that the test helper returns the sealed ToolResultMessage
      expect(_toolResult('id', 'c'), isA<ToolResultMessage>());
    });
  });
}
