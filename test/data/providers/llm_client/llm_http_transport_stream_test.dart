// Unit tests for LlmHttpTransport's streaming response-parse helper (issue
// #123). Pure-function coverage: SSE lines in, LlmResponseChunk out — no
// network, same shape as the non-streaming parse tests above it.
//
// The parser mirrors OpenAiCompatibleClient.stream's wire handling (data:
// lines, [DONE], delta.content, reasoning deltas, buffered tool_calls) so the
// two OpenAI-compatible streaming paths agree on chunk semantics.

import 'dart:convert';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/data/providers/llm_client/llm_http_transport.dart';
import 'package:zuraffa_agent/src/llm/llm_client.dart';

Stream<LlmResponseChunk> parse(List<String> lines) =>
    parseChatCompletionChunkStream(Stream<String>.fromIterable(lines));

Future<List<LlmResponseChunk>> drain(Stream<LlmResponseChunk> chunks) =>
    chunks.toList();

String data(Object json) => 'data: ${jsonEncode(json)}';

void main() {
  group('parseChatCompletionChunkStream (issue #123)', () {
    test('yields one content chunk per non-empty delta.content', () async {
      final chunks = await drain(
        parse([
          data({
            'choices': [
              {
                'index': 0,
                'delta': {'content': 'Hel'},
              },
            ],
          }),
          data({
            'choices': [
              {
                'index': 0,
                'delta': {'content': 'lo'},
              },
            ],
          }),
          'data: [DONE]',
        ]),
      );

      expect(chunks.map((c) => c.content), ['Hel', 'lo', null]);
      expect(chunks.last.isComplete, isTrue);
    });

    test('maps reasoning deltas to thinking chunks', () async {
      final chunks = await drain(
        parse([
          // OpenRouter-style `reasoning` and DeepSeek-style
          // `reasoning_content` both carry thinking text.
          data({
            'choices': [
              {
                'index': 0,
                'delta': {'reasoning': 'step '},
              },
            ],
          }),
          data({
            'choices': [
              {
                'index': 0,
                'delta': {'reasoning_content': 'one'},
              },
            ],
          }),
          'data: [DONE]',
        ]),
      );

      expect(chunks.map((c) => c.thinking), ['step ', 'one', null]);
      expect(
        chunks.whereType<LlmResponseChunk>().every(
          (c) => c.content == null || c.content!.isEmpty,
        ),
        isTrue,
      );
    });

    test(
      'buffers tool_calls fragments and emits them on finish_reason',
      () async {
        final chunks = await drain(
          parse([
            data({
              'choices': [
                {
                  'index': 0,
                  'delta': {
                    'tool_calls': [
                      {
                        'index': 0,
                        'id': 'call_1',
                        'function': {'name': 'search', 'arguments': '{"q":'},
                      },
                    ],
                  },
                },
              ],
            }),
            data({
              'choices': [
                {
                  'index': 0,
                  'delta': {
                    'tool_calls': [
                      {
                        'index': 0,
                        'function': {'arguments': '"zuraffa"}'},
                      },
                    ],
                  },
                },
              ],
            }),
            data({
              'choices': [
                {
                  'index': 0,
                  'delta': <String, dynamic>{},
                  'finish_reason': 'tool_calls',
                },
              ],
            }),
            'data: [DONE]',
          ]),
        );

        final toolChunk = chunks.firstWhere((c) => c.toolCalls.isNotEmpty);
        expect(toolChunk.toolCalls, hasLength(1));
        expect(toolChunk.toolCalls.single.id, 'call_1');
        expect(toolChunk.toolCalls.single.name, 'search');
        expect(toolChunk.toolCalls.single.arguments, {'q': 'zuraffa'});
        expect(toolChunk.finishReason, 'tool_calls');

        // Exactly one final chunk and no duplicates after [DONE].
        expect(chunks.where((c) => c.isComplete), hasLength(1));
      },
    );

    test(
      'captures usage from the trailing usage event and completes',
      () async {
        final chunks = await drain(
          parse([
            data({
              'choices': [
                {
                  'index': 0,
                  'delta': {'content': 'ok'},
                },
              ],
            }),
            data({
              'choices': <Object>[],
              'usage': {
                'prompt_tokens': 5,
                'completion_tokens': 2,
                'prompt_tokens_details': {'cached_tokens': 1},
                'completion_tokens_details': {'reasoning_tokens': 1},
              },
            }),
            'data: [DONE]',
          ]),
        );

        // content delta, then the trailing usage event finalizes the stream.
        expect(chunks, hasLength(2));
        expect(chunks[1].usage, isNotNull);
        expect(chunks[1].usage!.inputTokens, 5);
        expect(chunks[1].usage!.outputTokens, 2);
        expect(chunks[1].usage!.cachedTokens, 1);
        expect(chunks[1].usage!.thoughtTokens, 1);
        expect(chunks[1].isComplete, isTrue);
      },
    );

    test('finalizes even when the stream ends without [DONE]', () async {
      final chunks = await drain(
        parse([
          data({
            'choices': [
              {
                'index': 0,
                'delta': {'content': 'cut'},
              },
            ],
          }),
        ]),
      );

      expect(chunks, hasLength(2));
      expect(chunks.last.isComplete, isTrue);
      expect(chunks.last.finishReason, 'stop');
    });

    test('skips empty lines, comments, and malformed payloads', () async {
      final chunks = await drain(
        parse([
          '',
          ': keep-alive comment',
          'data: not-json',
          data({
            'choices': [
              {
                'index': 0,
                'delta': {'content': 'ok'},
              },
            ],
          }),
          'data: [DONE]',
        ]),
      );

      expect(chunks, hasLength(2)); // content + final
      expect(chunks.first.content, 'ok');
    });

    test('empty and whitespace-only deltas yield no chunks', () async {
      final chunks = await drain(
        parse([
          data({
            'choices': [
              {
                'index': 0,
                'delta': {'content': ''},
              },
            ],
          }),
          data({
            'choices': [
              {
                'index': 0,
                'delta': {'reasoning': ''},
              },
            ],
          }),
          data({
            'choices': [
              {'index': 0, 'delta': <String, dynamic>{}},
            ],
          }),
          'data: [DONE]',
        ]),
      );

      // Only the finalize chunk survives; empty deltas are dropped.
      expect(chunks, hasLength(1));
      expect(chunks.single.isComplete, isTrue);
    });
  });
}
