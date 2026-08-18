// Ported from pi_agent (~/Developer/pi/pi_agent, branch 001-dart-agent-package,
// lib/src/session_storage.dart). Source licensed BSD-3-Clause (ZikZak AI);
// modifications licensed MIT under zuraffa_agent. See NOTICE.
/// Concrete session storage implementations.
///
/// Deviations from the pi_agent source (per specs/002-state-and-sessions):
/// - `init()` returns a [StoreOpenResult] tear report (research R7);
/// - the JSONL codec is lossless: message payloads, the typed
///   [CompactionSummary], and the new [TurnRecord] / [ToolInvocationRecord] /
///   [UsageLedgerEntry] entries all round-trip (pi_agent kept only roles);
/// - [SessionStorage.removeEntry] supports branch pruning (US2);
/// - leaf id and metadata are persisted to the JSONL header line;
/// - `loadEntries` preserves insertion (log) order — the entry sequence a
///   writer appended, identical across Hive and JSONL for the same writes
///   (cross-store equivalence).
library;

import 'dart:convert';
import 'dart:io' as io;

import 'compaction.dart';
import 'session_storage.dart';
import 'types.dart';

final SessionInfo _defaultMeta = SessionInfo(
  id: '',
  name: '',
  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
);

/// In-memory session storage for testing and transient sessions.
class InMemorySessionStorage implements SessionStorage {
  final List<SessionTreeEntry> _entries = [];
  String? _leafId;
  SessionInfo? _metadata;

  @override
  Future<StoreOpenResult> init() async => const StoreOpenResult();

  @override
  Future<void> appendEntry(SessionTreeEntry entry) async => _entries.add(entry);

  @override
  Future<List<SessionTreeEntry>> loadEntries() async =>
      List<SessionTreeEntry>.from(_entries);

  @override
  Future<SessionTreeEntry?> findEntry(String id) async {
    for (final e in _entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  @override
  Future<void> setLeafId(String? leafId) async => _leafId = leafId;

  @override
  Future<String?> getLeafId() async => _leafId;

  @override
  Future<void> setMetadata(SessionInfo info) async => _metadata = info;

  @override
  Future<SessionInfo> getMetadata() async => _metadata ?? _defaultMeta;

  @override
  Future<void> removeEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> close() async {
    _entries.clear();
    _leafId = null;
    _metadata = null;
  }
}

/// JSONL file-based session storage.
///
/// On-disk format (contracts/session-api.md): one JSON object per line, the
/// first line a `_header` metadata object, then typed entry lines. Loading
/// stops at the first undecodable line and reports a [JsonlTear] with the
/// salvaged prefix (research R7).
class JsonlSessionStorage implements SessionStorage {
  /// Path to the JSONL file backing this storage.
  final String filePath;

  List<SessionTreeEntry>? _cache;
  String? _leafId;
  SessionInfo? _metadata;

  /// Creates JSONL storage backed by the given file path.
  JsonlSessionStorage(this.filePath);

  @override
  Future<StoreOpenResult> init() async {
    final file = io.File(filePath);
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    return _loadFromDisk();
  }

  @override
  Future<void> appendEntry(SessionTreeEntry entry) async {
    _cache ??= [];
    _cache!.add(entry);
    _leafId = entry.id;

    final line = jsonEncode(entryToJson(entry));
    final file = io.File(filePath);
    await file.writeAsString('$line\n', mode: io.FileMode.append);
  }

  @override
  Future<List<SessionTreeEntry>> loadEntries() async {
    if (_cache == null) {
      await _loadFromDisk();
    }
    return List<SessionTreeEntry>.from(_cache!);
  }

  @override
  Future<SessionTreeEntry?> findEntry(String id) async {
    final entries = await loadEntries();
    for (final e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  @override
  Future<void> setLeafId(String? leafId) async {
    _leafId = leafId;
    await _rewriteFile();
  }

  @override
  Future<String?> getLeafId() async => _leafId;

  @override
  Future<void> setMetadata(SessionInfo info) async {
    _metadata = info;
    await _rewriteFile();
  }

  @override
  Future<SessionInfo> getMetadata() async => _metadata ?? _defaultMeta;

  @override
  Future<void> removeEntry(String id) async {
    if (_cache == null) {
      await _loadFromDisk();
    }
    final before = _cache!.length;
    _cache!.removeWhere((e) => e.id == id);
    if (_cache!.length != before) {
      await _rewriteFile();
    }
  }

  @override
  Future<void> close() async {
    _cache = null;
  }

  /// Rewrites the whole file: header line (metadata + leaf) then entries.
  ///
  /// JSONL is append-only for entries; the header's leaf id and metadata
  /// change rarely (setLeafId/setMetadata), so a rewrite is acceptable and
  /// keeps the on-disk format exactly as contracted. The header carries the
  /// optional `metadata` map additively (the ported header predates
  /// [SessionInfo.metadata]).
  Future<void> _rewriteFile() async {
    final entries = _cache ?? <SessionTreeEntry>[];
    final meta = _metadata;
    final buffer = StringBuffer()
      ..writeln(jsonEncode(<String, dynamic>{
        '_header': true,
        'id': meta?.id ?? '',
        'name': meta?.name ?? '',
        'createdAt':
            (meta?.createdAt ?? _defaultMeta.createdAt).toIso8601String(),
        'updatedAt':
            (meta?.updatedAt ?? _defaultMeta.updatedAt).toIso8601String(),
        if (meta != null && meta.metadata.isNotEmpty) 'metadata': meta.metadata,
        if (_leafId != null) 'leafId': _leafId,
      }));
    for (final e in entries) {
      buffer.writeln(jsonEncode(entryToJson(e)));
    }
    await io.File(filePath).writeAsString(buffer.toString());
  }

  /// Loads the file, stopping at the first undecodable line (research R7).
  Future<StoreOpenResult> _loadFromDisk() async {
    final file = io.File(filePath);
    final entries = <SessionTreeEntry>[];
    final tears = <JsonlTear>[];

    if (await file.exists()) {
      final lines = await file.readAsLines();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        try {
          final decoded = jsonDecode(line);
          if (decoded is! Map<String, dynamic>) {
            throw const FormatException('line is not a JSON object');
          }
          if (decoded.containsKey('_header')) {
            final header = JsonlSessionMetadata.fromJson(decoded);
            final meta = decoded['metadata'];
            _metadata = SessionInfo(
              id: header.id,
              name: header.name,
              createdAt: _parseIso(header.createdAt),
              updatedAt: _parseIso(header.updatedAt),
              metadata: meta is Map<String, dynamic> ? meta : const {},
            );
            if (header.leafId != null) _leafId = header.leafId;
            continue;
          }
          entries.add(entryFromJson(decoded));
        } catch (e) {
          tears.add(JsonlTear(
            lineNumber: i + 1,
            reason: e.toString(),
            salvagedEntryCount: entries.length,
          ));
          break;
        }
      }
    }

    _cache = entries;
    if (_leafId == null && entries.isNotEmpty) {
      _leafId = entries.last.id;
    }
    return StoreOpenResult(tears: tears);
  }
}

DateTime _parseIso(String s) => DateTime.tryParse(s) ?? DateTime.fromMillisecondsSinceEpoch(0);

// ---------------------------------------------------------------------------
// Lossless JSON codec (entry <-> JSON). Every parse path throws FormatException
// on malformed input so the JSONL loader reports a tear at the right line.
// ---------------------------------------------------------------------------

/// Serializes a session-tree entry to its JSONL line object.
Map<String, dynamic> entryToJson(SessionTreeEntry entry) {
  final base = <String, dynamic>{
    'id': entry.id,
    'parentId': entry.parentId,
    'timestamp': entry.timestamp.toIso8601String(),
  };

  return switch (entry) {
    MessageEntry(:final role, :final message) => {
        ...base,
        'type': 'message',
        'role': role,
        'message': messageToJson(message),
      },
    ThinkingLevelChangeEntry(:final level) => {
        ...base,
        'type': 'thinkingLevelChange',
        'level': level.name,
      },
    ModelChangeEntry(:final provider, :final modelId) => {
        ...base,
        'type': 'modelChange',
        'provider': provider,
        'modelId': modelId,
      },
    CompactionEntry(
      :final summary,
      :final firstKeptEntryId,
      :final tokensBefore
    ) =>
      {
        ...base,
        'type': 'compaction',
        'summary': summaryToJson(summary),
        'firstKeptEntryId': firstKeptEntryId,
        'tokensBefore': tokensBefore,
      },
    BranchSummaryEntry(:final summary) => {
        ...base,
        'type': 'branchSummary',
        'summary': summary,
      },
    LabelEntry(:final targetId, :final label) => {
        ...base,
        'type': 'label',
        'targetId': targetId,
        if (label != null) 'label': label,
      },
    CustomEntry(:final customType, :final data) => {
        ...base,
        'type': 'custom',
        'customType': customType,
        if (data != null) 'data': data,
      },
    TurnRecord(
      :final turnNumber,
      :final messageEntryIds,
      :final stopReason,
      :final startedAt,
      :final endedAt,
      :final durationMs
    ) =>
      {
        ...base,
        'type': 'turn',
        'turnNumber': turnNumber,
        'messageEntryIds': messageEntryIds,
        if (stopReason != null) 'stopReason': stopReason.name,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt.toIso8601String(),
        'durationMs': durationMs,
      },
    ToolInvocationRecord(
      :final toolCallId,
      :final toolName,
      :final arguments,
      :final resultEntryId,
      :final isError,
      :final durationMs,
      :final artifactRefs
    ) =>
      {
        ...base,
        'type': 'toolInvocation',
        'toolCallId': toolCallId,
        'toolName': toolName,
        'arguments': arguments,
        if (resultEntryId != null) 'resultEntryId': resultEntryId,
        'isError': isError,
        'durationMs': durationMs,
        'artifactRefs': [
          for (final r in artifactRefs) artifactRefToJson(r),
        ],
      },
    UsageLedgerEntry(
      :final callId,
      :final turnNumber,
      :final model,
      :final inputTokens,
      :final outputTokens,
      :final cacheCreationInputTokens,
      :final cacheReadInputTokens
    ) =>
      {
        ...base,
        'type': 'usage',
        'callId': callId,
        'turnNumber': turnNumber,
        'model': modelToJson(model),
        'inputTokens': inputTokens,
        'outputTokens': outputTokens,
        if (cacheCreationInputTokens != null)
          'cacheCreationInputTokens': cacheCreationInputTokens,
        if (cacheReadInputTokens != null)
          'cacheReadInputTokens': cacheReadInputTokens,
      },
  };
}

/// Deserializes a JSONL line object into a session-tree entry.
///
/// Throws [FormatException] on any malformed field so the loader stops at the
/// first bad line and reports a tear.
SessionTreeEntry entryFromJson(Map<String, dynamic> json) {
  final type = _requiredString(json, 'type');
  final id = _requiredString(json, 'id');
  final parentId = json['parentId'] as String? ?? '';
  final timestamp = _requiredDateTime(json, 'timestamp');

  return switch (type) {
    'message' => MessageEntry(
        id: id,
        parentId: parentId,
        timestamp: timestamp,
        role: _messageRole(json['role']),
        message: messageFromJson(_requiredMap(json, 'message')),
      ),
    'thinkingLevelChange' => ThinkingLevelChangeEntry(
        id: id,
        parentId: parentId,
        timestamp: timestamp,
        level: _enumByName(ThinkingLevel.values, _requiredString(json, 'level')),
      ),
    'modelChange' => ModelChangeEntry(
        id: id,
        parentId: parentId,
        timestamp: timestamp,
        provider: _requiredString(json, 'provider'),
        modelId: _requiredString(json, 'modelId'),
      ),
    'compaction' => CompactionEntry(
        id: id,
        parentId: parentId,
        timestamp: timestamp,
        summary: summaryFromJson(_requiredMap(json, 'summary')),
        firstKeptEntryId: _requiredString(json, 'firstKeptEntryId'),
        tokensBefore: _requiredInt(json, 'tokensBefore'),
      ),
    'branchSummary' => BranchSummaryEntry(
        id: id,
        parentId: parentId,
        timestamp: timestamp,
        summary: _requiredString(json, 'summary'),
      ),
    'label' => LabelEntry(
        id: id,
        parentId: parentId,
        timestamp: timestamp,
        targetId: _requiredString(json, 'targetId'),
        label: json['label'] as String?,
      ),
    'custom' => CustomEntry(
        id: id,
        parentId: parentId,
        timestamp: timestamp,
        customType: _requiredString(json, 'customType'),
        data: json['data'] as Map<String, dynamic>?,
      ),
    'turn' => TurnRecord(
        id: id,
        parentId: parentId,
        timestamp: timestamp,
        turnNumber: _requiredInt(json, 'turnNumber'),
        messageEntryIds: _requiredStringList(json, 'messageEntryIds'),
        stopReason: json['stopReason'] == null
            ? null
            : _enumByName(
                StopReason.values, _requiredString(json, 'stopReason')),
        startedAt: _requiredDateTime(json, 'startedAt'),
        endedAt: _requiredDateTime(json, 'endedAt'),
        durationMs: _requiredInt(json, 'durationMs'),
      ),
    'toolInvocation' => ToolInvocationRecord(
        id: id,
        parentId: parentId,
        timestamp: timestamp,
        toolCallId: _requiredString(json, 'toolCallId'),
        toolName: _requiredString(json, 'toolName'),
        arguments: _requiredMap(json, 'arguments'),
        resultEntryId: json['resultEntryId'] as String?,
        isError: json['isError'] as bool? ?? false,
        durationMs: _requiredInt(json, 'durationMs'),
        artifactRefs: _requiredList(json, 'artifactRefs')
            .cast<Map<String, dynamic>>()
            .map(artifactRefFromJson)
            .toList(),
      ),
    'usage' => UsageLedgerEntry(
        id: id,
        parentId: parentId,
        timestamp: timestamp,
        callId: _requiredString(json, 'callId'),
        turnNumber: _requiredInt(json, 'turnNumber'),
        model: modelFromJson(_requiredMap(json, 'model')),
        inputTokens: _requiredInt(json, 'inputTokens'),
        outputTokens: _requiredInt(json, 'outputTokens'),
        cacheCreationInputTokens: json['cacheCreationInputTokens'] as int?,
        cacheReadInputTokens: json['cacheReadInputTokens'] as int?,
      ),
    _ => throw FormatException('unknown entry type: $type'),
  };
}

Map<String, dynamic> messageToJson(AgentMessage message) => switch (message) {
      UserMessage(:final content) => {
          'kind': 'user',
          'content': [for (final b in content) blockToJson(b)],
        },
      AssistantMessage(:final id, :final content, :final stopReason, :final usage) =>
        {
          'kind': 'assistant',
          if (id != null) 'id': id,
          'content': [for (final b in content) blockToJson(b)],
          if (stopReason != null) 'stopReason': stopReason.name,
          if (usage != null) 'usage': usageToJson(usage),
        },
      ToolResultMessage(
        :final toolCallId,
        :final toolName,
        :final content,
        :final isError
      ) =>
        {
          'kind': 'toolResult',
          'toolCallId': toolCallId,
          'toolName': toolName,
          'content': [for (final b in content) blockToJson(b)],
          'isError': isError,
        },
      CustomMessage(:final type, :final data, :final display) => {
          'kind': 'custom',
          'type': type,
          'data': data,
          'display': display,
        },
    };

AgentMessage messageFromJson(Map<String, dynamic> json) {
  final kind = _requiredString(json, 'kind');
  return switch (kind) {
    'user' => UserMessage(
        content: _blockListFromJson(json),
      ),
    'assistant' => AssistantMessage(
        id: json['id'] as String?,
        content: _blockListFromJson(json),
        stopReason: json['stopReason'] == null
            ? null
            : _enumByName(
                StopReason.values, _requiredString(json, 'stopReason')),
        usage: json['usage'] == null
            ? null
            : usageFromJson(_requiredMap(json, 'usage')),
      ),
    'toolResult' => ToolResultMessage(
        toolCallId: _requiredString(json, 'toolCallId'),
        toolName: _requiredString(json, 'toolName'),
        content: _blockListFromJson(json),
        isError: json['isError'] as bool? ?? false,
      ),
    'custom' => CustomMessage(
        type: _requiredString(json, 'type'),
        data: _requiredMap(json, 'data'),
        display: _requiredString(json, 'display'),
      ),
    _ => throw FormatException('unknown message kind: $kind'),
  };
}

Map<String, dynamic> blockToJson(ContentBlock block) => switch (block) {
      TextBlock(:final text) => {'block': 'text', 'text': text},
      ImageBlock(:final base64Data, :final mediaType) => {
          'block': 'image',
          'base64Data': base64Data,
          'mediaType': mediaType,
        },
      AudioBlock(:final base64Data, :final mediaType, :final transcript) => {
          'block': 'audio',
          'base64Data': base64Data,
          'mediaType': mediaType,
          if (transcript != null) 'transcript': transcript,
        },
      DocumentBlock(:final mediaType, :final base64Data, :final title) => {
          'block': 'document',
          'mediaType': mediaType,
          'base64Data': base64Data,
          if (title != null) 'title': title,
        },
      ToolCallBlock(:final id, :final name, :final arguments) => {
          'block': 'toolCall',
          'id': id,
          'name': name,
          'arguments': arguments,
        },
      ThinkingBlock(:final text) => {'block': 'thinking', 'text': text},
    };

ContentBlock blockFromJson(Map<String, dynamic> json) {
  final block = _requiredString(json, 'block');
  return switch (block) {
    'text' => TextBlock(_requiredString(json, 'text')),
    'image' => ImageBlock(
        base64Data: _requiredString(json, 'base64Data'),
        mediaType: _requiredString(json, 'mediaType'),
      ),
    'audio' => AudioBlock(
        base64Data: _requiredString(json, 'base64Data'),
        mediaType: _requiredString(json, 'mediaType'),
        transcript: json['transcript'] as String?,
      ),
    'document' => DocumentBlock(
        mediaType: _requiredString(json, 'mediaType'),
        base64Data: _requiredString(json, 'base64Data'),
        title: json['title'] as String?,
      ),
    'toolCall' => ToolCallBlock(
        id: _requiredString(json, 'id'),
        name: _requiredString(json, 'name'),
        arguments: _requiredMap(json, 'arguments'),
      ),
    'thinking' => ThinkingBlock(_requiredString(json, 'text')),
    _ => throw FormatException('unknown block type: $block'),
  };
}

Map<String, dynamic> usageToJson(Usage usage) => <String, dynamic>{
      'inputTokens': usage.inputTokens,
      'outputTokens': usage.outputTokens,
      if (usage.cacheCreationInputTokens != null)
        'cacheCreationInputTokens': usage.cacheCreationInputTokens,
      if (usage.cacheReadInputTokens != null)
        'cacheReadInputTokens': usage.cacheReadInputTokens,
    };

Usage usageFromJson(Map<String, dynamic> json) => Usage(
      inputTokens: _requiredInt(json, 'inputTokens'),
      outputTokens: _requiredInt(json, 'outputTokens'),
      cacheCreationInputTokens: json['cacheCreationInputTokens'] as int?,
      cacheReadInputTokens: json['cacheReadInputTokens'] as int?,
    );

Map<String, dynamic> modelToJson(Model model) => <String, dynamic>{
      'provider': model.provider,
      'modelId': model.modelId,
      'contextWindow': model.contextWindow,
      'supportsVision': model.supportsVision,
      'supportsThinking': model.supportsThinking,
      'supportsTools': model.supportsTools,
      if (model.extra != null && model.extra!.isNotEmpty) 'extra': model.extra,
    };

Model modelFromJson(Map<String, dynamic> json) => Model(
      provider: _requiredString(json, 'provider'),
      modelId: _requiredString(json, 'modelId'),
      contextWindow: _requiredInt(json, 'contextWindow'),
      supportsVision: json['supportsVision'] as bool? ?? false,
      supportsThinking: json['supportsThinking'] as bool? ?? false,
      supportsTools: json['supportsTools'] as bool? ?? true,
      extra: json['extra'] as Map<String, dynamic>?,
    );

Map<String, dynamic> summaryToJson(CompactionSummary summary) =>
    <String, dynamic>{
      'decisions': summary.decisions,
      'toolNames': summary.toolNames,
      'keyResults': summary.keyResults,
      if (summary.planState != null) 'planState': summary.planState,
      'artifacts': [
        for (final a in summary.artifacts) artifactRefToJson(a),
      ],
      if (summary.prose != null) 'prose': summary.prose,
    };

CompactionSummary summaryFromJson(Map<String, dynamic> json) =>
    CompactionSummary(
      decisions: _requiredStringList(json, 'decisions'),
      toolNames: _requiredStringList(json, 'toolNames'),
      keyResults: _requiredStringList(json, 'keyResults'),
      planState: json['planState'] as String?,
      artifacts: _requiredList(json, 'artifacts')
          .cast<Map<String, dynamic>>()
          .map(artifactRefFromJson)
          .toList(),
      prose: json['prose'] as String?,
    );

Map<String, dynamic> artifactRefToJson(ArtifactRef ref) =>
    {'kind': ref.kind, 'id': ref.id};

ArtifactRef artifactRefFromJson(Map<String, dynamic> json) => ArtifactRef(
      kind: _requiredString(json, 'kind'),
      id: _requiredString(json, 'id'),
    );

List<ContentBlock> _blockListFromJson(Map<String, dynamic> json) =>
    _requiredList(json, 'content')
        .cast<Map<String, dynamic>>()
        .map(blockFromJson)
        .toList();

List<dynamic> _requiredList(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is! List) throw FormatException('$key must be a list');
  return v;
}

List<String> _requiredStringList(Map<String, dynamic> json, String key) {
  final v = _requiredList(json, key);
  for (final e in v) {
    if (e is! String) throw FormatException('$key must contain only strings');
  }
  return v.cast<String>();
}

Map<String, dynamic> _requiredMap(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is! Map<String, dynamic>) throw FormatException('$key must be a map');
  return v;
}

String _requiredString(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is! String) throw FormatException('$key must be a string');
  return v;
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is! int) throw FormatException('$key must be an int');
  return v;
}

DateTime _requiredDateTime(Map<String, dynamic> json, String key) {
  final s = _requiredString(json, key);
  final dt = DateTime.tryParse(s);
  if (dt == null) throw FormatException('$key must be an ISO-8601 date');
  return dt;
}

T _enumByName<T extends Enum>(List<T> values, String name) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  throw FormatException('unknown enum value: $name');
}

String _messageRole(Object? role) {
  const allowed = {'user', 'assistant', 'toolResult', 'custom'};
  if (role is! String || !allowed.contains(role)) {
    throw FormatException('invalid message role: $role');
  }
  return role;
}
