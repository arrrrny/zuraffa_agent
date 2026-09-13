// HAND-CURATED — spec 110 (issue arrrrny/zuraffa_agent#122).
//
// SessionMigrator — the ordered registry of persisted session-schema
// migration steps. Steps operate on RAW entry maps BEFORE deserialization;
// unknown keys survive `fromJson`, so additive transforms are safe. The
// next real schema change is one function: register a step `(from → step)`,
// bump `SessionSchema.currentVersion`, add a fixture test.

import 'session_storage.dart';

/// A single migration step: from the map's registered version to the next.
typedef SessionMigrationStep =
    Map<String, dynamic> Function(Map<String, dynamic> raw);

/// Registry + runner for session-schema migrations (spec 110).
class SessionMigrator {
  /// The oldest schema version this registry can migrate from. Files
  /// without any version marker are v1 by definition (the entire
  /// pre-versioning corpus).
  static const int oldestSupportedVersion = 1;

  /// The ordered migration registry: keyed by the version the step
  /// migrates FROM.
  final Map<int, SessionMigrationStep> migrations;

  final int currentVersion;

  const SessionMigrator({
    required this.migrations,
    this.currentVersion = SessionSchema.currentVersion,
  });

  /// The shipped registry: 1→2 and 2→3 stamp each entry map with its target
  /// schema version. The steps are deliberately conservative — the real
  /// historical divergences don't exist yet; the machinery is the
  /// deliverable, so the next schema change is a one-function addition.
  static SessionMigrator standard() =>
      SessionMigrator(migrations: {1: _stamp(2), 2: _stamp(3)});

  static SessionMigrationStep _stamp(int version) =>
      (raw) => Map<String, dynamic>.of(raw)..['schemaVersion'] = version;

  /// Migrates one raw entry map from its version to the registry's current
  /// version, applying every registered step in order. A map already at the
  /// current version is returned unchanged (same instance). A map at a
  /// version greater than current is rejected — downgrade is not supported.
  Map<String, dynamic> migrate(Map<String, dynamic> raw) {
    final existing = raw['schemaVersion'];
    final from = existing is int
        ? existing
        : SessionMigrator.oldestSupportedVersion;
    if (from > currentVersion) {
      throw StateError(
        'session entry schemaVersion $from is newer than the supported '
        'version $currentVersion — downgrade is not supported',
      );
    }
    if (from == currentVersion) return raw;

    final out = Map<String, dynamic>.of(raw);
    for (var v = from; v < currentVersion; v++) {
      final step = migrations[v];
      if (step == null) {
        throw StateError('no migration registered from session schema v$v');
      }
      step(out);
      out['schemaVersion'] = v + 1;
    }
    return out;
  }
}
