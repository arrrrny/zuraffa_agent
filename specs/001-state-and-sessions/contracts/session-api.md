# Interface Contract: Session & Storage API

**Feature**: `001-state-and-sessions`  
**Date**: 2026-08-18  
**Spec**: [spec.md](../spec.md)

---

## 1. Storage Contract (`SessionStorage`)

```dart
/// Result metadata returned when opening a storage datasource.
class StoreOpenResult {
  final int loadedEntriesCount;
  final JsonlTear? tearReport;

  const StoreOpenResult({
    required this.loadedEntriesCount,
    this.tearReport,
  });
}

/// Diagnostic information when a corrupt JSONL tail is salvaged.
class JsonlTear {
  final int lineNumber;
  final String reason;
  final int salvagedEntryCount;

  const JsonlTear({
    required this.lineNumber,
    required this.reason,
    required this.salvagedEntryCount,
  });
}

/// Unified abstract storage interface for session tree persistence.
abstract interface class SessionStorage {
  /// Initializes the storage backend and returns load status.
  Future<StoreOpenResult> init();

  /// Persists a new entry into the session tree.
  Future<void> appendEntry(SessionTreeEntry entry);

  /// Retrieves an entry by its unique identifier.
  Future<SessionTreeEntry?> getEntry(String id);

  /// Retrieves all persisted entries in the session store.
  Future<List<SessionTreeEntry>> getEntries();

  /// Gets the currently active leaf entry identifier.
  Future<String?> getActiveLeafId();

  /// Updates the currently active leaf entry identifier.
  Future<void> setActiveLeafId(String leafId);

  /// Deletes specified entries from storage.
  Future<void> deleteEntries(Set<String> entryIds);

  /// Closes the storage backend and flushes resources.
  Future<void> close();
}
```

---

## 2. Agent Session API (`AgentSession`)

```dart
/// Context representation reconstructed from the active branch.
class SessionContext {
  final List<AgentMessage> messages;
  final Model? activeModel;
  final ThinkingLevel? activeThinkingLevel;
  final CompactionSummary? activeCompaction;

  const SessionContext({
    required this.messages,
    this.activeModel,
    this.activeThinkingLevel,
    this.activeCompaction,
  });
}

/// High-level session manager handling tree navigation, branching, and context reconstruction.
class AgentSession {
  final SessionStorage storage;

  AgentSession(this.storage);

  /// Initializes the underlying storage.
  Future<StoreOpenResult> init();

  /// Appends an [AgentMessage] to the active branch.
  Future<String> appendMessage(AgentMessage message);

  /// Appends a [TurnRecord] marking turn completion.
  Future<String> appendTurn(TurnRecord turn);

  /// Appends a [ToolInvocationRecord] for a single tool call.
  Future<String> appendToolInvocation(ToolInvocationRecord invocation);

  /// Appends a [UsageLedgerEntry] for token accounting.
  Future<String> appendUsage(UsageLedgerEntry usage);

  /// Appends a [CompactionEntry] recording context compaction.
  Future<String> appendCompaction(CompactionEntry compaction);

  /// Reconstructs the chronological conversation context for the active branch.
  Future<SessionContext> buildContext();

  /// Returns the chain of entries from active leaf to root.
  Future<List<SessionTreeEntry>> getBranch({String? leafId});

  /// Forks history from [atEntryId], setting it as the new branch point.
  Future<void> fork(String atEntryId);

  /// Switches the active leaf pointer to [leafId].
  Future<void> switchTo(String leafId);

  /// Returns a list of all current leaf/head entry IDs in the session tree.
  Future<List<String>> listBranchHeads();

  /// Deletes a branch leaf and prunes unreferenced ancestor entries.
  Future<void> deleteBranch(String leafId);
}
```

---

## 3. Storage Format Specifications

### 3.1 JSONL Format (`JsonlSessionStorage`)
- **First Line**: Header line `{"_header": {"version": 1, "created": "...", "activeLeafId": "..."}}`
- **Subsequent Lines**: Serialized JSON objects with `_type` discriminator (`message`, `turn`, `toolInvocation`, `usage`, `compaction`, etc.).
- **Tear Handling**: If parsing hits an invalid JSON line or truncated tail, parsing halts, all preceding lines are retained, and a `JsonlTear` is returned.

### 3.2 Hive Storage Format (`HiveSessionStorage`)
- **Box 1 (`entries`)**: Binary serialized `SessionTreeEntry` objects indexed by entry `id`.
- **Box 2 (`meta`)**: Key-value metadata including `activeLeafId`, `schemaVersion`, and index tables.
