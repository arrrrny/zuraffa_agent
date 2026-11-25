/// Host-injection port for credentials / secure storage (FR-006).
///
/// Technology-agnostic: the host supplies the production adapter (keychain,
/// secret manager, encrypted store); tests use [InMemoryAgentCredentialPort].
/// Business logic depends on this interface, never on a global service locator.
library;

/// Resolves and stores provider API keys on behalf of the host.
abstract class AgentCredentialPort {
  /// Resolves the API key for [provider], or `null` when it is not configured.
  Future<String?> resolveApiKey(String provider);

  /// Stores [key] for [provider].
  Future<void> storeApiKey(String provider, String key);

  /// Clears any stored key for [provider].
  Future<void> clearApiKey(String provider);
}

/// Pure-Dart in-memory [AgentCredentialPort] for tests and local runs.
class InMemoryAgentCredentialPort implements AgentCredentialPort {
  final Map<String, String> _keys = {};

  @override
  Future<String?> resolveApiKey(String provider) async => _keys[provider];

  @override
  Future<void> storeApiKey(String provider, String key) async =>
      _keys[provider] = key;

  @override
  Future<void> clearApiKey(String provider) async => _keys.remove(provider);
}
