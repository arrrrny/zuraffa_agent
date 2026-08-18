// AgentSession — high-level session manager for tree navigation, branching,
// and context reconstruction.
//
// This is integration glue: hand-written against zfa-generated entity types
// (TurnRecord, ToolInvocationRecord, UsageLedgerEntry, CompactionEntry,
// CompactionSummary, Model, etc.) and the abstract SessionStorage interface.

import 'types.dart';
import 'session_storage.dart';

/// Context representation reconstructed from the active branch.
class SessionContext {
  final List<AgentMessage> messages;
  final Model? activeModel;
  final String? activeThinkingLevel;
  final CompactionSummary? activeCompaction;

  const SessionContext({
    required this.messages,
    this.activeModel,
    this.activeThinkingLevel,
    this.activeCompaction,
  });
}

/// High-level session manager handling tree navigation, branching,
/// and context reconstruction.
///
/// The session maintains a tree of [SessionTreeEntry] instances persisted
/// via [SessionStorage]. A single active leaf pointer tracks which branch
/// is currently selected.
class AgentSession {
  final SessionStorage storage;

  AgentSession(this.storage);

  /// Initializes the underlying storage.
  Future<StoreOpenResult> init() => storage.init();

  /// Appends an [AgentMessage] to the active branch.
  Future<String> appendMessage(AgentMessage message) async {
    final id = _generateId();
    final parentId = await storage.getActiveLeafId();
    final entry = MessageEntry(
      id: id,
      parentId: parentId,
      timestamp: DateTime.now().toUtc(),
      message: message,
    );
    await storage.appendEntry(entry);
    await storage.setActiveLeafId(id);
    return id;
  }

  /// Appends a [TurnRecord] marking turn completion.
  Future<String> appendTurn(TurnRecord turn) async {
    final id = _generateId();
    final parentId = await storage.getActiveLeafId();
    final entry = TurnRecordEntry(
      id: id,
      parentId: parentId,
      timestamp: DateTime.now().toUtc(),
      record: turn,
    );
    await storage.appendEntry(entry);
    await storage.setActiveLeafId(id);
    return id;
  }

  /// Appends a [ToolInvocationRecord] for a single tool call.
  Future<String> appendToolInvocation(
    ToolInvocationRecord invocation, {
    Map<String, dynamic> arguments = const {},
    List<ArtifactRef> artifactRefs = const [],
  }) async {
    final id = _generateId();
    final parentId = await storage.getActiveLeafId();
    final entry = ToolInvocationEntry(
      id: id,
      parentId: parentId,
      timestamp: DateTime.now().toUtc(),
      record: invocation,
      arguments: arguments,
      artifactRefs: artifactRefs,
    );
    await storage.appendEntry(entry);
    await storage.setActiveLeafId(id);
    return id;
  }

  /// Appends a [UsageLedgerEntry] for token accounting.
  Future<String> appendUsage(
    UsageLedgerEntry usage, {
    Model? model,
  }) async {
    final id = _generateId();
    final parentId = await storage.getActiveLeafId();
    final entry = UsageEntry(
      id: id,
      parentId: parentId,
      timestamp: DateTime.now().toUtc(),
      record: usage,
      model: model,
    );
    await storage.appendEntry(entry);
    await storage.setActiveLeafId(id);
    return id;
  }

  /// Appends a [CompactionEntry] recording context compaction.
  Future<String> appendCompaction(
    CompactionEntry compaction, {
    required CompactionSummary summary,
  }) async {
    final id = _generateId();
    final parentId = await storage.getActiveLeafId();
    final entry = CompactionTreeEntry(
      id: id,
      parentId: parentId,
      timestamp: DateTime.now().toUtc(),
      record: compaction,
      summary: summary,
    );
    await storage.appendEntry(entry);
    await storage.setActiveLeafId(id);
    return id;
  }

  /// Reconstructs the chronological conversation context for the active branch.
  Future<SessionContext> buildContext() async {
    final branch = await getBranch();
    final messages = <AgentMessage>[];
    Model? activeModel;
    String? activeThinkingLevel;
    CompactionSummary? activeCompaction;

    for (final entry in branch) {
      switch (entry) {
        case MessageEntry():
          messages.add(entry.message);
        case UsageEntry():
          activeModel = entry.model ?? activeModel;
        case ThinkingLevelEntry():
          activeThinkingLevel = entry.record.thinkingLevel;
        case CompactionTreeEntry():
          activeCompaction = entry.summary;
        default:
          // TurnRecord, ToolInvocation, ModelChange, BranchSummary,
          // Label, Custom — not included in conversation context.
          break;
      }
    }

    return SessionContext(
      messages: messages,
      activeModel: activeModel,
      activeThinkingLevel: activeThinkingLevel,
      activeCompaction: activeCompaction,
    );
  }

  /// Returns the chain of entries from active leaf to root.
  Future<List<SessionTreeEntry>> getBranch({String? leafId}) async {
    final targetLeaf = leafId ?? await storage.getActiveLeafId();
    if (targetLeaf == null) return [];

    final allEntries = await storage.getEntries();
    final entryMap = <String, SessionTreeEntry>{};
    for (final e in allEntries) {
      entryMap[e.id] = e;
    }

    // Walk from leaf to root via parentId links.
    final branch = <SessionTreeEntry>[];
    String? currentId = targetLeaf;
    while (currentId != null) {
      final entry = entryMap[currentId];
      if (entry == null) break;
      branch.add(entry);
      currentId = entry.parentId;
    }

    return branch.reversed.toList();
  }

  /// Forks history from [atEntryId], creating a new branch head.
  ///
  /// After forking, the new branch shares all ancestry up to [atEntryId]
  /// and can diverge independently.
  Future<void> fork(String atEntryId) async {
    // Create a branch summary entry at the fork point.
    final id = _generateId();
    final entry = BranchSummaryTreeEntry(
      id: id,
      parentId: atEntryId,
      timestamp: DateTime.now().toUtc(),
      record: BranchSummaryEntry(
        id: id,
        parentId: atEntryId,
        timestamp: DateTime.now().toUtc(),
        summary: 'Forked from $atEntryId',
      ),
    );
    await storage.appendEntry(entry);
    await storage.setActiveLeafId(id);
  }

  /// Switches the active leaf pointer to [leafId].
  Future<void> switchTo(String leafId) async {
    await storage.setActiveLeafId(leafId);
  }

  /// Returns a list of all current leaf/head entry IDs in the session tree.
  Future<List<String>> listBranchHeads() async {
    final allEntries = await storage.getEntries();
    if (allEntries.isEmpty) return [];

    // An entry is a leaf if no other entry has it as parentId.
    final parentIds = <String>{
      for (final e in allEntries)
        if (e.parentId != null) e.parentId!,
    };

    return allEntries
        .where((e) => !parentIds.contains(e.id))
        .map((e) => e.id)
        .toList();
  }

  /// Deletes a branch leaf and prunes unreferenced ancestor entries.
  Future<void> deleteBranch(String leafId) async {
    final allEntries = await storage.getEntries();
    final entryMap = <String, SessionTreeEntry>{};
    for (final e in allEntries) {
      entryMap[e.id] = e;
    }

    // Collect child counts to determine which ancestors are shared.
    final childCounts = <String, int>{};
    for (final e in allEntries) {
      if (e.parentId != null) {
        childCounts[e.parentId!] = (childCounts[e.parentId!] ?? 0) + 1;
      }
    }

    // Walk from leaf upward, pruning entries with only one child reference.
    final toDelete = <String>{};
    String? currentId = leafId;
    while (currentId != null) {
      final entry = entryMap[currentId];
      if (entry == null) break;
      toDelete.add(currentId);

      final count = childCounts[currentId] ?? 0;
      if (count > 1) {
        // This entry is shared by other branches — stop pruning.
        break;
      }
      currentId = entry.parentId;
    }

    if (toDelete.isNotEmpty) {
      await storage.deleteEntries(toDelete);
    }

    // If the active leaf was deleted, fall back to the latest remaining entry.
    final activeLeaf = await storage.getActiveLeafId();
    if (activeLeaf != null && toDelete.contains(activeLeaf)) {
      final remaining = await storage.getEntries();
      if (remaining.isNotEmpty) {
        await storage.setActiveLeafId(remaining.last.id);
      } else {
        await storage.setActiveLeafId('');
      }
    }
  }

  String _generateId() => generateEntryId();
}
