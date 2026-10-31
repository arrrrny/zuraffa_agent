// Tests for EngineLoopExecutor.runTurnStream (issue #123): the streaming
// turn driver. Uses a fake LlmClientProvider so no network is touched, and
// probe StreamControllers whose onPause/onResume/onCancel callbacks expose
// the producer side of the bounded-buffer backpressure contract.

import 'dart:async';

import 'package:test/test.dart';

import 'package:zuraffa_agent/src/domain/entities/engine_loop/engine_loop.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_message.dart';
import 'package:zuraffa_agent/src/domain/entities/provider_config/provider_config.dart';
import 'package:zuraffa_agent/src/data/providers/engine_loop/engine_loop_executor.dart';
import 'package:zuraffa_agent/src/data/providers/llm_client/llm_client_provider.dart';
import 'package:zuraffa_agent/src/llm/llm_client.dart';

/// LLM client whose streamComplete is scripted per turn by [streamFactory].
class FakeStreamingLlmClient extends LlmClientProvider {
  FakeStreamingLlmClient(this.streamFactory)
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

  final Stream<LlmResponseChunk> Function(List<ChatMessage> messages)
  streamFactory;

  @override
  Stream<LlmResponseChunk> streamComplete(List<ChatMessage> messages) =>
      streamFactory(messages);
}

const loop = EngineLoop(
  id: 'loop-1',
  sessionId: 's1',
  maxTurns: 3,
  wallClockTimeoutMs: 60000,
  repetitionThreshold: 5,
);

const messages = [ChatMessage(role: 'user', content: 'hi')];

/// Lets the event loop settle (microtasks + zero-duration timers) so that
/// stream deliveries, pause requests, and resume requests have landed.
Future<void> flush() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

LlmResponseChunk contentChunk(String text) => LlmResponseChunk(content: text);

void main() {
  group('EngineLoopExecutor.runTurnStream (issue #123)', () {
    test('rejects invalid turn numbers synchronously, before subscribing', () {
      final executor = EngineLoopExecutor(
        loop,
        FakeStreamingLlmClient((_) => const Stream<LlmResponseChunk>.empty()),
      );
      // Both validations mirror runTurn: non-positive and over-cap.
      expect(
        () => executor.runTurnStream(messages, turnNumber: 0),
        throwsA(isA<StateError>()),
      );
      expect(
        () => executor.runTurnStream(messages, turnNumber: 4),
        throwsA(isA<StateError>()),
      );
    });

    test(
      'allows turnNumber == maxTurns (the cap is inclusive, like runTurn)',
      () async {
        final executor = EngineLoopExecutor(
          loop,
          FakeStreamingLlmClient((_) => Stream.value(contentChunk('ok'))),
        );
        final chunks = await executor
            .runTurnStream(messages, turnNumber: loop.maxTurns)
            .toList();
        expect(chunks.single.content, 'ok');
      },
    );

    test('forwards provider chunks in order and terminates', () async {
      final executor = EngineLoopExecutor(
        loop,
        FakeStreamingLlmClient(
          (_) => Stream.fromIterable([
            contentChunk('Hel'),
            contentChunk('lo'),
            const LlmResponseChunk(
              usage: LlmUsage(inputTokens: 1, outputTokens: 2),
              isComplete: true,
              finishReason: 'stop',
            ),
          ]),
        ),
      );

      final chunks = await executor
          .runTurnStream(messages, turnNumber: 1)
          .toList();

      expect(chunks.map((c) => c.content), ['Hel', 'lo', null]);
      expect(chunks.last.isComplete, isTrue);
      expect(chunks.last.finishReason, 'stop');
      expect(chunks.last.usage?.outputTokens, 2);
    });

    test('backpressure: a paused consumer pauses the producer at the buffer '
        'capacity and no chunk is lost or reordered', () async {
      var sourcePauses = 0;
      var sourceResumes = 0;
      final source = StreamController<LlmResponseChunk>(
        onPause: () => sourcePauses++,
        onResume: () => sourceResumes++,
      );
      addTearDown(() async {
        await source.close();
      });

      // Capacity 2: the high watermark that pauses the producer.
      final executor = EngineLoopExecutor(
        loop,
        FakeStreamingLlmClient((_) => source.stream),
        streamBufferCapacity: 2,
      );

      final received = <LlmResponseChunk>[];
      var done = false;
      final sub = executor
          .runTurnStream(messages, turnNumber: 1)
          .listen(received.add, onDone: () => done = true);

      // Fast consumer: chunks flow straight through, the producer is
      // never paused because the buffer never reaches capacity.
      source.add(contentChunk('a'));
      await flush();
      source.add(contentChunk('b'));
      await flush();
      source.add(contentChunk('c'));
      await flush();
      expect(received.map((c) => c.content), ['a', 'b', 'c']);
      expect(sourcePauses, 0);

      // Pause the consumer: deliveries stop while the producer keeps
      // pumping. Crossing capacity pauses the producer.
      sub.pause();
      await flush();
      source.add(contentChunk('d'));
      await flush();
      source.add(contentChunk('e'));
      await flush();
      expect(received.map((c) => c.content), ['a', 'b', 'c']);
      expect(sourcePauses, greaterThanOrEqualTo(1));

      // Resume: the buffered chunks deliver first, in order, and the
      // producer is released once the buffer drains.
      sub.resume();
      await flush();
      expect(
        received.map((c) => c.content),
        containsAllInOrder(['a', 'b', 'c', 'd']),
      );
      expect(sourceResumes, greaterThanOrEqualTo(1));

      source.add(contentChunk('f'));
      await flush();
      await source.close();
      await flush();

      expect(done, isTrue);
      // The streaming contract: nothing lost, nothing reordered.
      expect(received.map((c) => c.content).toList(), [
        'a',
        'b',
        'c',
        'd',
        'e',
        'f',
      ]);
      await sub.cancel();
    });

    test(
      'cancelling the consumer tears down the producer subscription',
      () async {
        var cancelled = false;
        final source = StreamController<LlmResponseChunk>(
          onCancel: () async {
            cancelled = true;
          },
        );
        addTearDown(() async {
          await source.close();
        });

        final executor = EngineLoopExecutor(
          loop,
          FakeStreamingLlmClient((_) => source.stream),
        );

        final sub = executor
            .runTurnStream(messages, turnNumber: 1)
            .listen((_) {});
        await flush();
        await sub.cancel();
        await flush();

        expect(cancelled, isTrue);
      },
    );

    test('a provider stream error propagates to the consumer', () async {
      final executor = EngineLoopExecutor(
        loop,
        FakeStreamingLlmClient(
          (_) => Stream<LlmResponseChunk>.error(
            StateError('gateway exploded mid-stream'),
          ),
        ),
      );

      await expectLater(
        executor.runTurnStream(messages, turnNumber: 1).drain<void>(),
        throwsA(isA<StateError>()),
      );
    });

    test('non-positive streamBufferCapacity is rejected', () {
      expect(
        () => EngineLoopExecutor(
          loop,
          FakeStreamingLlmClient((_) => const Stream<LlmResponseChunk>.empty()),
          streamBufferCapacity: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
