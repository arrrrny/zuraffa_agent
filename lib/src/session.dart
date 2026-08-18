// Ported from pi_agent (~/Developer/pi/pi_agent, branch 001-dart-agent-package,
// lib/src/session.dart). Source licensed BSD-3-Clause (ZikZak AI);
// modifications licensed MIT under zuraffa_agent. See NOTICE.
/// Agent session: branching tree-of-entries conversation container.
///
/// Deviations from the pi_agent source (per specs/002-state-and-sessions):
/// - renamed `Session` -> [AgentSession] (the spec's entity name);
/// - NEW granular-entity appends: [appendTurn], [appendToolInvocation],
///   [appendUsage], and the typed-summary [appendCompaction];
/// - NEW branch management: [fork], [switchTo], [listBranchHeads],
///   [deleteBranch] (research R8: derived child counts, no refcounts);
/// - entry ids come from the collision-free monotonic generator
///   ([newEntryId], research R6) instead of bare microseconds;
/// - orphan-parent appends are rejected with [SessionTreeException]
///   (data-model.md validation rules).
library;

import 'types.dart';
import 'session_storage.dart';

/// Thrown when a session-tree operation violates tree invariants.
///
/// Covers orphan-parent appends, references to unknown entries, and
/// turn records whose message entry ids are off the active branch
/// (data-model.md validation rules).
class SessionTreeException implements Exception {
  /// Human-readable description of the violation.
  final String message;

  /// Creates a session-tree exception.
  SessionTreeException(this.message);

  @override
  String toString() => 'SessionTreeException: $message';
}

/// Manages a conversation history as a tree of entries over a
/// [SessionStorage].
///
/// All appends extend the active branch (the branch ending at the current
/// leaf). [fork] / [switchTo] / [moveTo] move the leaf; [buildContext]
/// reconstructs the active branch's conversation. Single-writer per session.
class AgentSession {
  final SessionStorage _storage;
  Future<void>? _initFuture;
  Map<String, SessionTreeEntry>? _entries;
  String? _leafId;

  /// Creates a session backed by the given storage.
  AgentSession(this._storage);

  /// The storage backing this session.
  SessionStorage get storage => _storage;

  /// Appends a message entry to the active branch.
  Future<String> appendMessage(AgentMessage message) async {
    await _ensureInit();
    final role = switch (message) {
      UserMessage() => 'user',
      AssistantMessage() => 'assistant',
      ToolResultMessage() => 'toolResult',
      CustomMessage() => 'custom',
    };
    final entry = MessageEntry(
      id: newEntryId(),
      parentId: _leafId ?? '',
      timestamp: DateTime.now(),
      role: role,
      message: message,
    );
    await _append(entry);
    return entry.id;
  }

  /// Appends a thinking level change entry.
  Future<String> appendThinkingLevelChange(ThinkingLevel level) async {
    await _ensureInit();
    final entry = ThinkingLevelChangeEntry(
      id: newEntryId(),
      parentId: _leafId ?? '',
      timestamp: DateTime.now(),
      level: level,
    );
    await _append(entry);
    return entry.id;
  }

  /// Appends a model change entry.
  Future<String> appendModelChange(String provider, String modelId) async {
    await _ensureInit();
    final entry = ModelChangeEntry(
      id: newEntryId(),
      parentId: _leafId ?? '',
      timestamp: DateTime.now(),
      provider: provider,
      modelId: modelId,
    );
    await _append(entry);
    return entry.id;
  }

  /// Appends a label entry pointing at [targetId].
  Future<String> appendLabel(String targetId, {String? label}) async {
    await _ensureInit();
    if (!_entries!.containsKey(targetId)) {
      throw SessionTreeException('label target not found: $targetId');
    }
    final entry = LabelEntry(
      id: newEntryId(),
      parentId: _leafId ?? '',
      timestamp: DateTime.now(),
      targetId: targetId,
      label: label,
    );
    await _append(entry);
    return entry.id;
  }

  /// Appends a custom entry (extensibility point).
  Future<String> appendCustomEntry(String customType,
      {Map<String, dynamic>? data}) async {
    await _ensureInit();
    final entry = CustomEntry(
      id: newEntryId(),
      parentId: _leafId ?? '',
      timestamp: DateTime.now(),
      customType: customType,
      data: data,
    );
    await _append(entry);
    return entry.id;
  }

  /// Moves the session leaf to [entryId] (fork/switch/resume).
  ///
  /// With [summary], appends a [BranchSummaryEntry] naming the new branch.
  /// A null [entryId] moves the leaf to the root (empty session).
  Future<String?> moveTo(String? entryId, {String? summary}) async {
    await _ensureInit();
    if (entryId != null) _requireEntry(entryId);
    await _setLeaf(entryId);
    if (summary != null && entryId != null) {
      final entry = BranchSummaryEntry(
        id: newEntryId(),
        parentId: entryId,
        timestamp: DateTime.now(),
        summary: summary,
      );
      await _append(entry);
      return summary;
    }
    return null;
  }

  /// Appends a turn record to the active branch.
  ///
  /// Validates that every referenced message entry exists on the active
  /// branch (data-model.md same-branch rule) before appending. The caller's
  /// entry identity (id/timestamp) is preserved; only the parent is
  /// re-pointed at the current leaf.
  Future<String> appendTurn(TurnRecord turn) async {
    await _ensureInit();
    for (final messageId in turn.messageEntryIds) {
      if (!_entries!.containsKey(messageId)) {
        throw SessionTreeException(
            'turn references unknown entry: $messageId');
      }
      if (!_onActiveBranch(messageId)) {
        throw SessionTreeException(
            'turn references entry off the active branch: $messageId');
      }
    }
    final entry = TurnRecord(
      id: turn.id,
      parentId: _leafId ?? '',
      timestamp: turn.timestamp,
      turnNumber: turn.turnNumber,
      messageEntryIds: turn.messageEntryIds,
      stopReason: turn.stopReason,
      startedAt: turn.startedAt,
      endedAt: turn.endedAt,
      durationMs: turn.durationMs,
    );
    await _append(entry);
    return entry.id;
  }

  /// Appends a tool invocation record to the active branch.
  ///
  /// The caller's entry identity (id/timestamp) is preserved; only the
  /// parent is re-pointed at the current leaf.
  Future<String> appendToolInvocation(ToolInvocationRecord invocation) async {
    await _ensureInit();
    final entry = ToolInvocationRecord(
      id: invocation.id,
      parentId: _leafId ?? '',
      timestamp: invocation.timestamp,
      toolCallId: invocation.toolCallId,
      toolName: invocation.toolName,
      arguments: invocation.arguments,
      resultEntryId: invocation.resultEntryId,
      isError: invocation.isError,
      durationMs: invocation.durationMs,
      artifactRefs: invocation.artifactRefs,
    );
    await _append(entry);
    return entry.id;
  }

  /// Appends a per-LLM-call usage ledger entry to the active branch.
  ///
  /// The caller's entry identity (id/timestamp) is preserved; only the
  /// parent is re-pointed at the current leaf.
  Future<String> appendUsage(UsageLedgerEntry usage) async {
    await _ensureInit();
    final entry = UsageLedgerEntry(
      id: usage.id,
      parentId: _leafId ?? '',
      timestamp: usage.timestamp,
      callId: usage.callId,
      turnNumber: usage.turnNumber,
      model: usage.model,
      inputTokens: usage.inputTokens,
      outputTokens: usage.outputTokens,
      cacheCreationInputTokens: usage.cacheCreationInputTokens,
      cacheReadInputTokens: usage.cacheReadInputTokens,
    );
    await _append(entry);
    return entry.id;
  }

  /// Appends a compaction entry (typed summary) to the active branch.
  ///
  /// The entry must be parented at the current leaf — compaction never
  /// mutates sibling branches (invariant I2).
  Future<String> appendCompaction(CompactionEntry entry) async {
    await _ensureInit();
    if (entry.parentId != (_leafId ?? '')) {
      throw SessionTreeException(
          'compaction parent ${entry.parentId} is not the current leaf '
          '$_leafId');
    }
    await _append(entry);
    return entry.id;
  }

  /// Reconstructs the session context from the active branch.
  Future<SessionContext> buildContext() async {
    final branch = await getBranch();
    final messages = <AgentMessage>[];
    var thinkingLevel = ThinkingLevel.off;
    Model? model;

    for (final entry in branch.reversed) {
      switch (entry) {
        case MessageEntry(:final message):
          messages.add(message);
        case ThinkingLevelChangeEntry(:final level):
          thinkingLevel = level;
        case ModelChangeEntry(:final provider, :final modelId):
          model = Model(
              provider: provider, modelId: modelId, contextWindow: 128000);
        case CompactionEntry():
        case BranchSummaryEntry():
        case LabelEntry():
        case CustomEntry():
        case TurnRecord():
        case ToolInvocationRecord():
        case UsageLedgerEntry():
          break;
      }
    }

    return SessionContext(
      messages: messages,
      thinkingLevel: thinkingLevel,
      model: model ??
          const Model(
              provider: 'openai', modelId: 'gpt-4o', contextWindow: 128000),
    );
  }

  /// Gets the active branch's entries, leaf to root (ported semantics).
  Future<List<SessionTreeEntry>> getBranch({String? fromId}) async {
    await _ensureInit();
    final leafId = fromId ?? _leafId;
    if (leafId == null || leafId.isEmpty) return [];

    final result = <SessionTreeEntry>[];
    String? currentId = leafId;
    while (currentId != null && currentId.isNotEmpty) {
      final entry = _entries![currentId];
      if (entry == null) break;
      result.add(entry);
      currentId = entry.parentId.isEmpty ? null : entry.parentId;
    }
    return result;
  }

  /// Gets all entries in storage (insertion order).
  Future<List<SessionTreeEntry>> getEntries() async {
    await _ensureInit();
    return _storage.loadEntries();
  }

  /// Gets a specific entry by ID.
  Future<SessionTreeEntry?> getEntry(String id) async {
    await _ensureInit();
    return _entries![id];
  }

  /// Gets session metadata.
  Future<SessionInfo> getMetadata() async {
    await _ensureInit();
    return _storage.getMetadata();
  }

  /// Forks a new branch at [atEntryId].
  ///
  /// The new branch shares ancestry up to and including [atEntryId] and
  /// diverges from its first child position; the branch leaf is
  /// [atEntryId] (or the appended [BranchSummaryEntry] when [summary] is
  /// given). Returns the new branch's leaf id.
  Future<String> fork(String atEntryId, {String? summary}) async {
    await _ensureInit();
    _requireEntry(atEntryId);
    await _setLeaf(atEntryId);
    if (summary != null) {
      final entry = BranchSummaryEntry(
        id: newEntryId(),
        parentId: atEntryId,
        timestamp: DateTime.now(),
        summary: summary,
      );
      await _append(entry);
      return entry.id;
    }
    return atEntryId;
  }

  /// Switches the active branch to [entryId]'s branch.
  Future<void> switchTo(String entryId) async {
    await _ensureInit();
    _requireEntry(entryId);
    await _setLeaf(entryId);
  }

  /// Lists branch heads: entries with no children (excluding pure metadata
  /// leaves such as [LabelEntry] / [CustomEntry]) plus labeled ("named")
  /// entries. Sorted for determinism.
  Future<List<String>> listBranchHeads() async {
    await _ensureInit();
    final children = _childCounts();
    final labeled = <String>{
      for (final e in _entries!.values)
        if (e is LabelEntry && e.label != null) e.targetId,
    };
    final heads = <String>[
      for (final e in _entries!.values)
        if (e is! LabelEntry &&
            e is! CustomEntry &&
            ((children[e.id] ?? 0) == 0 || labeled.contains(e.id)))
          e.id,
    ];
    heads.sort();
    return heads;
  }

  /// Deletes the branch ending at [leafId].
  ///
  /// Prunes upward while the derived child count of each entry is zero;
  /// stops at the first entry that still has children, so shared ancestry
  /// is retained (research R8 — child counts derived on demand, no
  /// persistent refcounts). Returns the number of pruned entries.
  ///
  /// When the pruned branch was the active one, the session leaf moves to
  /// the retained ancestor. A non-leaf [leafId] prunes nothing.
  Future<int> deleteBranch(String leafId) async {
    await _ensureInit();
    if (!_entries!.containsKey(leafId)) {
      throw SessionTreeException('unknown branch leaf: $leafId');
    }
    final children = _childCounts();
    var pruned = 0;
    String? retainedLeaf;
    var current = leafId;
    while (current.isNotEmpty) {
      if ((children[current] ?? 0) > 0) {
        retainedLeaf = current;
        break;
      }
      final entry = _entries![current];
      if (entry == null) break;
      await _storage.removeEntry(current);
      _entries!.remove(current);
      pruned++;
      // Keep the derived counts current as we prune upward.
      if (entry.parentId.isNotEmpty) {
        children[entry.parentId] = (children[entry.parentId] ?? 0) - 1;
      }
      retainedLeaf = entry.parentId.isEmpty ? null : entry.parentId;
      current = entry.parentId;
    }

    if (_leafId == leafId || (_leafId != null && !_entries!.containsKey(_leafId))) {
      await _setLeaf(retainedLeaf);
    }
    return pruned;
  }

  // -------------------------------------------------------------------------

  Future<void> _ensureInit() async {
    _initFuture ??= _init();
    await _initFuture;
  }

  Future<void> _init() async {
    await _storage.init();
    final entries = await _storage.loadEntries();
    _entries = {for (final e in entries) e.id: e};
    _leafId = await _storage.getLeafId();
  }

  Future<void> _append(SessionTreeEntry entry) async {
    if (entry.parentId.isNotEmpty && !_entries!.containsKey(entry.parentId)) {
      throw SessionTreeException(
          'orphan parent ${entry.parentId} for entry ${entry.id}');
    }
    if (_entries!.containsKey(entry.id)) {
      throw SessionTreeException('duplicate entry id: ${entry.id}');
    }
    await _storage.appendEntry(entry);
    _entries![entry.id] = entry;
    await _setLeaf(entry.id);
  }

  Future<void> _setLeaf(String? leafId) async {
    _leafId = leafId;
    await _storage.setLeafId(leafId);
  }

  void _requireEntry(String id) {
    if (!_entries!.containsKey(id)) {
      throw SessionTreeException('unknown entry: $id');
    }
  }

  bool _onActiveBranch(String id) {
    var current = _leafId;
    while (current != null && current.isNotEmpty) {
      if (current == id) return true;
      final entry = _entries![current];
      if (entry == null) return false;
      current = entry.parentId.isEmpty ? null : entry.parentId;
    }
    return false;
  }

  Map<String, int> _childCounts() {
    final children = <String, int>{};
    for (final e in _entries!.values) {
      if (e.parentId.isNotEmpty) {
        children[e.parentId] = (children[e.parentId] ?? 0) + 1;
      }
    }
    return children;
  }
}
