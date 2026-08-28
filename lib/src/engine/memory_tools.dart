// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// Spec 074 — memory tools: the agent-facing surface of the three-layer
// memory system (spec 073).
//
// An agent cannot call a Dart API — it calls tools. This library gives
// AgentMemorySystem its tool surface:
//
//   MemoryTools.declarations    — AgentTool declarations (house tool
//                                 model, R3.1/R3.2: typed params schema,
//                                 RiskTier.safe — memory writes are not
//                                 destructive, the layers are
//                                 append-oriented value stores)
//   MemoryToolDispatcher        — implements ToolDispatcher; bridges tool
//                                 calls onto AgentMemorySystem
//   MemoryPromptProjection      — renders the system-prompt digest of
//                                 what the agent remembers
//
// Failure policy: model-generated arguments are untrusted input.
// dispatch() returns ToolDispatchResult(success: false, error: ...)
// for argument-shaped problems (missing content, unknown link type,
// unknown endpoints, unknown tool) — the LLM sees the reason and can
// correct itself. Exceptions are for programmer errors only.
//
// The dispatcher can serve as the inner dispatcher of an allowlist
// dispatcher (spec 070's composition): memory tools compose with the
// sub-agent and swarm stacks.

import '../domain/entities/agent_tool/agent_tool.dart';
import '../domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
import 'agent_memory.dart';
import 'tool_dispatcher.dart';

/// The [AgentTool] declarations for the memory tool suite — what a
/// registry holds and a model sees.
class MemoryTools {
  MemoryTools._();

  /// `memory_remember` — store a fact, note, or learning.
  static const AgentTool rememberTool = AgentTool(
    id: 'memory_remember',
    description: 'Store a durable fact or a session note in agent memory. '
        'Use session_id to scope the note to the current session; omit it '
        'to remember across sessions. Returns the stored memory id.',
    riskTier: RiskTier.safe,
    executionMode: ExecutionMode.sequential,
    paramsSchema: {
      'type': 'object',
      'properties': {
        'id': {'type': 'string', 'description': 'Optional explicit id'},
        'content': {'type': 'string', 'description': 'What to remember'},
        'tags': {
          'type': 'array',
          'items': {'type': 'string'},
          'description': 'Optional tags',
        },
        'salience': {
          'type': 'number',
          'description': 'Optional 0.0..1.0 importance, default 0.5',
        },
        'session_id': {
          'type': 'string',
          'description': 'Scope the note to this session',
        },
      },
      'required': ['content'],
    },
  );

  /// `memory_recall` — search both memory layers.
  static const AgentTool recallTool = AgentTool(
    id: 'memory_recall',
    description: 'Search long-term and session memory by keyword. Returns '
        'ranked lines: layer, id, salience, content.',
    riskTier: RiskTier.safe,
    executionMode: ExecutionMode.sequential,
    paramsSchema: {
      'type': 'object',
      'properties': {
        'query': {'type': 'string', 'description': 'Keyword to search for'},
        'limit': {'type': 'number', 'description': 'Optional cap on hits'},
      },
      'required': ['query'],
    },
  );

  /// `memory_link` — cross-reference two memories.
  static const AgentTool linkTool = AgentTool(
    id: 'memory_link',
    description: 'Cross-reference two memories with a typed link: '
        'supports, contradicts, supersedes, derivedFrom, or relatesTo.',
    riskTier: RiskTier.safe,
    executionMode: ExecutionMode.sequential,
    paramsSchema: {
      'type': 'object',
      'properties': {
        'from_id': {'type': 'string'},
        'to_id': {'type': 'string'},
        'type': {
          'type': 'string',
          'enum': [
            'supports',
            'contradicts',
            'supersedes',
            'derivedFrom',
            'relatesTo',
          ],
        },
        'note': {'type': 'string', 'description': 'Optional why'},
      },
      'required': ['from_id', 'to_id', 'type'],
    },
  );

  /// All three declarations, unmodifiable.
  static List<AgentTool> get declarations => List.unmodifiable(const [
        rememberTool,
        recallTool,
        linkTool,
      ]);
}

/// Bridges tool dispatches onto an [AgentMemorySystem] — the runtime
/// behind `MemoryTools.declarations`.
class MemoryToolDispatcher implements ToolDispatcher {
  MemoryToolDispatcher({required this.memory});

  final AgentMemorySystem memory;
  int _counter = 0;

  @override
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  }) async {
    switch (toolName) {
      case 'memory_remember':
        return _remember(arguments);
      case 'memory_recall':
        return _recall(arguments);
      case 'memory_link':
        return _link(arguments);
      default:
        return _failure('unknown memory tool: $toolName');
    }
  }

  @override
  Future<List<ToolDispatchResult>> dispatchBatch({
    required List<ToolCall> calls,
    required bool isInternalMission,
  }) async => [
        for (final call in calls)
          await dispatch(
            toolName: call.toolName,
            arguments: call.arguments,
            isInternalMission: isInternalMission,
          ),
      ];

  @override
  List<String> validateSchema({
    required Map<String, dynamic> schema,
    required Map<String, dynamic> arguments,
  }) {
    final violations = <String>[];
    final required = schema['required'];
    if (required is List) {
      for (final key in required) {
        if (!arguments.containsKey(key)) {
          violations.add('missing required argument: $key');
        }
      }
    }
    return violations;
  }

  @override
  bool checkRiskTier({
    required String riskTier,
    required bool isInternalMission,
  }) =>
      true; // every memory tool is RiskTier.safe

  // Tool implementations -------------------------------------------------

  Future<ToolDispatchResult> _remember(Map<String, dynamic> arguments) async {
    final content = arguments['content'];
    if (content is! String || content.trim().isEmpty) {
      return _failure(
          'memory_remember requires non-empty string "content"');
    }
    final salienceArg = arguments['salience'];
    var salience = 0.5;
    if (salienceArg != null) {
      if (salienceArg is! num ||
          salienceArg.toDouble() < 0.0 ||
          salienceArg.toDouble() > 1.0) {
        return _failure(
            'salience must be a number within 0.0..1.0 (got: $salienceArg)');
      }
      salience = salienceArg.toDouble();
    }
    final tagsArg = arguments['tags'];
    if (tagsArg != null && tagsArg is! List) {
      return _failure('tags must be an array of strings');
    }
    final tags = <String>{
      if (tagsArg != null)
        for (final t in tagsArg as List)
          if (t is String) t,
    };
    final idArg = arguments['id'];
    final id = idArg is String && idArg.isNotEmpty ? idArg : _nextId();
    final sessionIdArg = arguments['session_id'];
    final sessionId =
        sessionIdArg is String && sessionIdArg.isNotEmpty ? sessionIdArg : null;

    final record = MemoryRecord(
      id: id,
      content: content,
      tags: tags,
      source: sessionId != null
          ? MemorySource(sessionId: sessionId)
          : MemorySource(agentName: 'memory-tool'),
      salience: salience,
    );
    try {
      memory.remember(record, sessionId: sessionId);
    } on ArgumentError catch (e) {
      return _failure(e.message?.toString() ?? 'invalid memory record');
    }
    return ToolDispatchResult(
      success: true,
      result: 'remembered: $id',
      error: '',
      artifactRefs: const [],
    );
  }

  Future<ToolDispatchResult> _recall(Map<String, dynamic> arguments) async {
    final query = arguments['query'];
    if (query is! String || query.trim().isEmpty) {
      return _failure('memory_recall requires non-empty string "query"');
    }
    final limitArg = arguments['limit'];
    int? limit;
    if (limitArg != null) {
      if (limitArg is! num || limitArg.toInt() < 1) {
        return _failure(
            'limit must be a positive number (got: $limitArg)');
      }
      limit = limitArg.toInt();
    }
    final hits = memory.recall(query, limit: limit);
    if (hits.isEmpty) {
      return ToolDispatchResult(
        success: true,
        result: 'no memories match "$query"',
        error: '',
        artifactRefs: const [],
      );
    }
    final lines = [
      for (final hit in hits)
        '${hit.layer.name} | ${hit.record.id} | '
        'salience ${hit.record.salience.toStringAsFixed(1)} | '
        '${hit.record.content}',
    ];
    return ToolDispatchResult(
      success: true,
      result: lines.join('\n'),
      error: '',
      artifactRefs: const [],
    );
  }

  Future<ToolDispatchResult> _link(Map<String, dynamic> arguments) async {
    final fromId = arguments['from_id'];
    final toId = arguments['to_id'];
    final typeArg = arguments['type'];
    if (fromId is! String || toId is! String || typeArg is! String) {
      return _failure(
          'memory_link requires string from_id, to_id, and type');
    }
    MemoryLinkType type;
    try {
      type = MemoryLinkType.values.byName(typeArg);
    } on ArgumentError {
      return _failure(
          'unknown link type "$typeArg" — expected one of: '
          '${MemoryLinkType.values.map((t) => t.name).join(', ')}');
    }
    final noteArg = arguments['note'];
    final note = noteArg is String && noteArg.isNotEmpty ? noteArg : null;

    try {
      memory.link(fromId, toId, type, note: note);
    } on ArgumentError catch (e) {
      return _failure(e.message?.toString() ?? 'invalid link');
    }
    return ToolDispatchResult(
      success: true,
      result: 'linked: $fromId ${type.name} $toId',
      error: '',
      artifactRefs: const [],
    );
  }

  String _nextId() {
    _counter++;
    return 'mem-$_counter';
  }

  ToolDispatchResult _failure(String error) => ToolDispatchResult(
        success: false,
        result: '',
        error: error,
        artifactRefs: const [],
      );
}

/// Renders the system-prompt digest of what the agent remembers: the top
/// long-term memories by salience, optionally with the current session's
/// notes prepended. Empty memory renders an empty list — callers omit
/// the memory section entirely.
class MemoryPromptProjection {
  MemoryPromptProjection({required this.memory});

  final AgentMemorySystem memory;

  /// The top [limit] long-term memories by salience (desc, then
  /// createdAt desc) as prompt lines `"- [id] content"`.
  List<String> render({int limit = 10}) {
    final ranked = [...memory.longTermMemory.all]..sort((a, b) {
        final bySalience = b.salience.compareTo(a.salience);
        if (bySalience != 0) return bySalience;
        return b.createdAt.compareTo(a.createdAt);
      });
    return List.unmodifiable([
      for (final record in ranked.take(limit))
        '- [${record.id}] ${record.content}',
    ]);
  }

  /// [render] with the session's notes (insertion order, capped by
  /// [limit]) prepended, each marked `[session] `.
  List<String> renderWithSession(String sessionId, {int limit = 10}) {
    final sessionLines = [
      for (final record in memory.sessionMemory.forSession(sessionId).take(limit))
        '- [session] [${record.id}] ${record.content}',
    ];
    return List.unmodifiable([...sessionLines, ...render(limit: limit)]);
  }
}
