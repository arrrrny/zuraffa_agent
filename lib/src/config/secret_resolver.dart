// HAND-CURATED — spec 107 (issue arrrrny/zuraffa_agent#121).
//
// SecretResolver — how consumers hand the engine credentials without ever
// putting them in a configuration document. Implement this interface to
// resolve from your own sources; [NullSecretResolver] is the shipped stub
// (resolves nothing, never throws for absence).

/// Resolves secrets from operator-chosen sources.
///
/// Implementations must never throw for "not found" — return `null` — and
/// must not log secret material. Resolution failures (I/O, connectivity)
/// MAY throw; absence MAY NOT.
abstract class SecretResolver {
  /// Resolves [key] from the process environment.
  Future<String?> fromEnv(String key);

  /// Resolves the secret stored at file [path].
  Future<String?> fromFile(String path);

  /// Resolves the secret at the vault [uri] (e.g. `vault://mount/secret`).
  /// Shipped as a stub interface: consumers implement this against their
  /// own vault client.
  Future<String?> fromVault(Uri uri);
}

/// The shipped no-op resolver: every source reports absence.
class NullSecretResolver implements SecretResolver {
  const NullSecretResolver();

  @override
  Future<String?> fromEnv(String key) async => null;

  @override
  Future<String?> fromFile(String path) async => null;

  @override
  Future<String?> fromVault(Uri uri) async => null;
}
