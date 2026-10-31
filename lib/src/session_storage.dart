// Abstract Session Storage Contract

import 'retention_policy.dart';
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

  /// Writes a versioned snapshot of the current state to the file at
  /// [dest] (issue #135).
  ///
  /// The envelope is the versioned session-file format (spec 110) with one
  /// extra `_backup` provenance line: a `_schema` header line carries the
  /// schema version (PS-1), the provenance line records format + creation
  /// time + entry count, the `_meta` line carries the active leaf, then one
  /// entry line per entry — so a backup file is itself a valid session
  /// store. Written atomically (temp + rename).
  Future<void> backup(String dest);

  /// Replaces the current state with the snapshot at [src] (issue #135).
  ///
  /// Strict: a snapshot newer than [SessionSchema.currentVersion] is
  /// refused (downgrade is not supported, matching [init]); older
  /// snapshots migrate through the [SessionMigrator] registry; a malformed
  /// envelope throws. The replacement is durable when the future
  /// completes.
  Future<void> restore(String src);

  /// Enforces [policy] against this store (issue #135): drops entries
  /// strictly older than `maxAge`, keeps only the newest `maxCount`, and
  /// drops oldest-first until the serialized state fits `maxBytes`.
  /// Returns what was removed. An active-leaf pointer whose entry was
  /// pruned is cleared. A pruned state is durable when the future
  /// completes.
  Future<PruneResult> prune(RetentionPolicy policy, {DateTime? now});

  /// Closes the storage backend and flushes resources.
  Future<void> close();
}
