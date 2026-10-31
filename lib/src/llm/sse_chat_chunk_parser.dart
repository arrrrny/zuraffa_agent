// Shared OpenAI-compatible SSE chunk parser (issue #123 review).
//
// One pure parser for BOTH OpenAI-compatible streaming paths —
// `OpenAiCompatibleClient.stream` and the legacy `LlmHttpTransport`'s
// `parseChatCompletionChunkStream` — instead of twin ~90-line state machines
// that had already drifted (the transport copy mapped reasoning deltas to
// thinking chunks while the provider-client copy silently dropped them).
//
// Living in lib/src/llm keeps the dependency direction legal: the transport
// (the only lib/src file importing dart:io) may depend on llm/, never the
// other way around (constitution VII).
//
// Wire contract (identical for both call sites):
//
// * `data:` lines carry one JSON event each; `data: [DONE]` ends the
//   stream. Empty lines, `: comment` keep-alives, and malformed payloads
//   are skipped without killing the stream.
// * `delta.content` / `delta.reasoning` / `delta.reasoning_content` map to
//   content / thinking chunks (empty deltas are dropped).
// * `delta.tool_calls` fragments accumulate per index slot and are emitted
//   as one chunk when `finish_reason: tool_calls` arrives (or at stream
//   end).
// * A trailing usage event (empty `choices`) updates usage and finalizes
//   the stream; a stream that ends without `[DONE]` is finalized anyway so
//   consumers always see exactly one `isComplete: true` chunk.

import 'dart:convert';

import 'llm_client.dart';

/// Parses an OpenAI-compatible streaming (SSE) response body into
/// `LlmResponseChunk`s.
Stream<LlmResponseChunk> parseOpenAiSseChunkStream(
  Stream<String> lines,
) async* {
  final toolBuffers = <int, _SseToolBuffer>{};
  var finishReason = 'stop';
  LlmUsage? usage;
  var toolCallsEmitted = false;
  var finalEmitted = false;

  Stream<LlmResponseChunk> finalize() async* {
    if (!toolCallsEmitted && toolBuffers.isNotEmpty) {
      toolCallsEmitted = true;
      yield LlmResponseChunk(
        toolCalls: [
          for (final buffer in toolBuffers.values)
            LlmToolCall(
              id: buffer.id ?? '',
              name: buffer.name,
              arguments: parseStreamingToolArguments(buffer.arguments),
            ),
        ],
      );
    }
    if (!finalEmitted) {
      finalEmitted = true;
      yield LlmResponseChunk(
        usage: usage,
        isComplete: true,
        finishReason: finishReason,
      );
    }
  }

  await for (final line in lines) {
    if (line.isEmpty || line.startsWith(':')) continue;
    if (!line.startsWith('data:')) continue;
    final payload = line.substring(5).trim();
    if (payload == '[DONE]') {
      yield* finalize();
      return;
    }
    final Map<String, dynamic> event;
    try {
      event = jsonDecode(payload) as Map<String, dynamic>;
    } on FormatException {
      continue; // Skip malformed events without killing the stream.
    }

    final choices = (event['choices'] as List?) ?? const [];
    if (choices.isEmpty) {
      final rawUsage = event['usage'];
      if (rawUsage is Map) usage = _parseSseUsage(rawUsage);
      yield* finalize();
      continue;
    }
    final choice = choices.first as Map;
    final delta = (choice['delta'] as Map?) ?? const {};
    for (final fragment in (delta['tool_calls'] as List?) ?? const []) {
      final f = fragment as Map;
      final index = (f['index'] as num?)?.toInt() ?? 0;
      final buffer = toolBuffers.putIfAbsent(index, _SseToolBuffer.new);
      final id = f['id'] as String?;
      if (id != null && id.isNotEmpty) buffer.id ??= id;
      final function = f['function'] as Map?;
      if (function != null) {
        final name = function['name'] as String?;
        if (name != null && name.isNotEmpty) buffer.name += name;
        buffer.arguments += (function['arguments'] as String?) ?? '';
      }
    }
    final reasoning =
        (delta['reasoning'] as String?) ??
        (delta['reasoning_content'] as String?);
    if (reasoning != null && reasoning.isNotEmpty) {
      yield LlmResponseChunk(thinking: reasoning);
    }
    final content = delta['content'] as String?;
    if (content != null && content.isNotEmpty) {
      yield LlmResponseChunk(content: content);
    }
    final reason = choice['finish_reason'] as String?;
    if (reason != null) {
      finishReason = reason;
      if (reason == 'tool_calls' && toolBuffers.isNotEmpty) {
        toolCallsEmitted = true;
        yield LlmResponseChunk(
          toolCalls: [
            for (final buffer in toolBuffers.values)
              LlmToolCall(
                id: buffer.id ?? '',
                name: buffer.name,
                arguments: parseStreamingToolArguments(buffer.arguments),
              ),
          ],
          finishReason: reason,
        );
      }
    }
  }
  // Stream ended without an explicit [DONE] sentinel — finalize anyway.
  yield* finalize();
}

/// Buffer accumulating one tool-call's streamed fragments for one index
/// slot.
class _SseToolBuffer {
  String? id;
  String name = '';
  String arguments = '';
}

/// Parses streaming usage (`prompt_tokens` / `completion_tokens` shape) into
/// the chunk currency.
LlmUsage _parseSseUsage(dynamic usage) {
  if (usage is! Map) return const LlmUsage();
  return LlmUsage(
    inputTokens: (usage['prompt_tokens'] as num?)?.toInt() ?? 0,
    outputTokens: (usage['completion_tokens'] as num?)?.toInt() ?? 0,
    cachedTokens:
        ((usage['prompt_tokens_details'] as Map?)?['cached_tokens'] as num?)
            ?.toInt() ??
        0,
    thoughtTokens:
        ((usage['completion_tokens_details'] as Map?)?['reasoning_tokens']
                as num?)
            ?.toInt() ??
        0,
  );
}

/// Tolerates malformed streamed tool arguments (spec 007 AC-2 analogue):
/// any unparsable payload defaults to an empty map.
Map<String, dynamic> parseStreamingToolArguments(String raw) {
  if (raw.isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on FormatException {
      // Fall through to the empty map.
    }
  }
  return const {};
}
