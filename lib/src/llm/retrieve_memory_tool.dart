// Runtime lineage: ported from dart_agent_core (MIT License, Copyright (c)
// 2024-2026 contributors) — see NOTICE. dart_agent_core is NOT a dependency
// of this package (constitution VIII): re-implemented in-tree per
// specs/010-episodic-memory/spec.md with this attribution retained.

import '../domain/entities/episodic_memory/episodic_memory.dart';
import 'episodic_memory_store.dart';
import 'llm_client.dart';

/// A single row of a paginated memory listing: identity + summary + message
/// count, deliberately WITHOUT the original messages (the model follows up
/// with a snapshot_id lookup when it needs the full originals — spec 010
/// FR-004).
class RetrieveMemoryListingItem {
  /// The identifier.
  final String id;

  /// The summary.
  final String summary;

  /// The message count.
  final int messageCount;

  /// Creates a retrieve memory listing item.
  const RetrieveMemoryListingItem({
    required this.id,
    required this.summary,
    required this.messageCount,
  });
}

/// Typed error codes for retrieve_memory results (spec 010 FR-002).
enum RetrieveMemoryErrorCode {
  /// The requested memory was not found.
  notFound,

  /// The query parameters were invalid.
  invalidParameters,
}

/// A typed retrieve_memory failure — never thrown; the engine renders it as
/// the tool result so a misbehaving model call degrades gracefully.
class RetrieveMemoryError {
  /// The code.
  final RetrieveMemoryErrorCode code;

  /// The message.
  final String message;

  /// Creates a retrieve memory error.
  const RetrieveMemoryError({required this.code, required this.message});
}

/// The result of one retrieve_memory execution (spec 010 US2).
///
/// Exactly one shape is populated: [memory] for a snapshot_id hit,
/// [listing] for a paginated listing, or [error] for a typed failure.
class RetrieveMemoryResult {
  /// True unless a typed error occurred (an empty page is still found=true).
  final bool found;

  /// The full memory (summary + original messages) for a snapshot_id lookup.
  final EpisodicMemory? memory;

  /// The paginated listing rows for a limit/offset call.
  final List<RetrieveMemoryListingItem>? listing;

  /// The typed error, if any.
  final RetrieveMemoryError? error;

  /// Creates a retrieve memory result.
  const RetrieveMemoryResult({
    required this.found,
    this.memory,
    this.listing,
    this.error,
  });
}

/// The model-facing `retrieve_memory` tool (spec 010 FR-002 / US2): exposes
/// episodic memories created by earlier compressions.
///
/// Parameters (all optional):
/// - `snapshot_id` — return that specific memory including its original
///   messages;
/// - `limit` / `offset` — page through memories in insertion order.
///
/// The [spec] surface is an [LlmToolSpec] (spec 007 tool shape) the engine
/// advertises to the model; [execute] is the engine-side invocation.
class RetrieveMemoryTool {
  /// The store.
  final EpisodicMemoryStore store;

  /// Creates a retrieve memory tool.
  RetrieveMemoryTool({required this.store});

  /// The tool definition advertised to the model.
  LlmToolSpec get spec => const LlmToolSpec(
    name: 'retrieve_memory',
    description:
        'Retrieve earlier conversation history that was '
        'compressed. Call with snapshot_id to get one memory including '
        'its original messages, or with limit/offset to page through '
        'memory summaries (oldest first).',
    parameters: {
      'type': 'object',
      'properties': {
        'snapshot_id': {
          'type': 'string',
          'description':
              'Return this specific memory (full original '
              'messages included).',
        },
        'limit': {
          'type': 'integer',
          'description': 'Page size for summary listings.',
          'minimum': 1,
        },
        'offset': {
          'type': 'integer',
          'description': 'Number of memories to skip (oldest first).',
          'minimum': 0,
        },
      },
    },
  );

  /// Executes one retrieve_memory call with raw model-supplied parameters.
  RetrieveMemoryResult execute(Map<String, dynamic> params) {
    final snapshotId = params['snapshot_id'];

    if (snapshotId != null) {
      if (snapshotId is! String) {
        return const RetrieveMemoryResult(
          found: false,
          error: RetrieveMemoryError(
            code: RetrieveMemoryErrorCode.invalidParameters,
            message: 'snapshot_id must be a string.',
          ),
        );
      }
      final memory = store.retrieve(snapshotId);
      if (memory == null) {
        return RetrieveMemoryResult(
          found: false,
          error: RetrieveMemoryError(
            code: RetrieveMemoryErrorCode.notFound,
            message: 'No episodic memory with snapshot_id "$snapshotId".',
          ),
        );
      }
      return RetrieveMemoryResult(found: true, memory: memory);
    }

    int? limit;
    final rawLimit = params['limit'];
    if (rawLimit is int) {
      limit = rawLimit;
    } else if (rawLimit is num) {
      limit = rawLimit.toInt();
    }
    int offset = 0;
    final rawOffset = params['offset'];
    if (rawOffset is int) {
      offset = rawOffset;
    } else if (rawOffset is num) {
      offset = rawOffset.toInt();
    }

    final page = store.list(limit: limit, offset: offset);
    return RetrieveMemoryResult(
      found: true,
      listing: [
        for (final memory in page)
          RetrieveMemoryListingItem(
            id: memory.id,
            summary: memory.summary,
            messageCount: memory.messages.length,
          ),
      ],
    );
  }
}
