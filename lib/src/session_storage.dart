// Abstract Session Storage Contract

import 'types.dart';

/// The persisted session-tree schema contract (spec 110, issue #122).
/// Bump [currentVersion] and register a migration step on every schema
/// change — see ARCHITECTURE.md for the migration policy.
abstract final class SessionSchema {
  static const int currentVersion = 3;
  static const String headerKey = '_schema';
}

/// Result metadata returned when opening a storage datasource.
class StoreOpenResult {
  final int loadedEntriesCount;
  final JsonlTear? tearReport;

  /// The schema version the store is at after [init] completed (spec 110).
  final int? schemaVersion;

  /// When a migration ran at open time: the version migrated FROM.
  /// Null when the store was already current (or brand new).
  final int? migratedFromVersion;

  const StoreOpenResult({
    required this.loadedEntriesCount,
    this.tearReport,
    this.schemaVersion,
    this.migratedFromVersion,
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

  /// Lazy entry stream (spec 114, issue #136): iterate without
  /// materializing the whole store; early exit stops the pull.
  Stream<SessionTreeEntry> entries();

  /// Gets the currently active leaf entry identifier.
  Future<String?> getActiveLeafId();

  /// Updates the currently active leaf entry identifier.
  Future<void> setActiveLeafId(String leafId);

  /// Deletes specified entries from storage.
  Future<void> deleteEntries(Set<String> entryIds);

  /// Closes the storage backend and flushes resources.
  Future<void> close();
}
