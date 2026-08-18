// Abstract Session Storage Contract

import 'types.dart';

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
