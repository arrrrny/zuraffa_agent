// Ported from pi_agent (~/Developer/pi/pi_agent, branch 001-dart-agent-package).
// Source licensed BSD-3-Clause (ZikZak AI); modifications licensed MIT under
// zuraffa_agent. See NOTICE.
/// Session storage contract shared by every persistence backend.
///
/// Deviations from the pi_agent source (per specs/002-state-and-sessions):
/// - `init()` returns a [StoreOpenResult] carrying a tear report instead of
///   `void` (corrupt-JSONL-tail edge case, research R7);
/// - this file declares the interface only — `InMemorySessionStorage` and
///   `JsonlSessionStorage` live in `session_storage_impl.dart`, and the
///   Hive implementation in `hive_session_store.dart`, keeping each import
///   surface minimal.
library;

import 'types.dart';

/// Result of opening a store: carries the tear report, empty when clean.
class StoreOpenResult {
  /// Tears detected while loading persisted state.
  final List<JsonlTear> tears;

  /// Creates an open result.
  const StoreOpenResult({this.tears = const []});

  /// True when the loaded state was clean.
  bool get isClean => tears.isEmpty;
}

/// A tear detected in a persisted append-only log.
class JsonlTear {
  /// 1-based line number of the first undecodable line.
  final int lineNumber;

  /// Why the line could not be decoded.
  final String reason;

  /// Number of valid entries loaded before the tear.
  final int salvagedEntryCount;

  /// Creates a tear report.
  const JsonlTear({
    required this.lineNumber,
    required this.reason,
    required this.salvagedEntryCount,
  });

  @override
  String toString() =>
      'JsonlTear(line: $lineNumber, reason: $reason, salvaged: '
      '$salvagedEntryCount)';
}

/// Abstract interface for session entry storage.
abstract class SessionStorage {
  /// Initialize storage and load persisted state.
  ///
  /// Returns a [StoreOpenResult] whose tear report is non-empty when a
  /// corrupt log tail was detected (salvaged prefix loaded, load stopped
  /// at the first undecodable line).
  Future<StoreOpenResult> init();

  /// Append an entry to storage.
  Future<void> appendEntry(SessionTreeEntry entry);

  /// Load all entries from storage.
  Future<List<SessionTreeEntry>> loadEntries();

  /// Find a specific entry by ID.
  Future<SessionTreeEntry?> findEntry(String id);

  /// Set the current leaf entry ID.
  Future<void> setLeafId(String? leafId);

  /// Get the current leaf entry ID.
  Future<String?> getLeafId();

  /// Set session metadata.
  Future<void> setMetadata(SessionInfo info);

  /// Get session metadata.
  Future<SessionInfo> getMetadata();

  /// Close storage and release resources.
  Future<void> close();
}
