// AgentPlatform — the pure-Dart host seam (spec 115).
//
// The engine never imports Flutter; a federated trio of packages
// (packages/zuraffa_agent_android|ios|macos, bridged through
// packages/zuraffa_agent_platform_interface) binds a concrete
// implementation at app startup by replacing [instance].

/// The host platform seam: agent home directory + secure key-value
/// storage for provider API keys.
abstract interface class AgentPlatform {
  /// The host-provided home directory for agent data (Application
  /// Support on Apple platforms, filesDir on Android), or null when the
  /// host cannot provide one.
  Future<String?> getAgentHome();

  /// Reads [key] from the host secure store; null means absent.
  Future<String?> secureRead(String key);

  /// Writes [value] under [key] in the host secure store.
  Future<void> secureWrite(String key, String value);

  /// Deletes [key] from the host secure store.
  Future<void> secureDelete(String key);
}

/// The bound platform implementation. Hosts (or the federated platform
/// packages' registration) replace this before the engine touches the
/// seam; the default throws [UnimplementedError] naming the missing
/// binding so a pure-Dart consumer gets a named error, not a silent
/// no-op.
set agentPlatformInstance(AgentPlatform platform) {
  AgentPlatformBinding.instance = platform;
}

abstract final class AgentPlatformBinding {
  /// The bound implementation; replace via [instance] or the
  /// [agentPlatformInstance] setter.
  static AgentPlatform instance = const _UnboundAgentPlatform();

  /// Test seam: restores the unbound default.
  static void reset() {
    instance = const _UnboundAgentPlatform();
  }
}

/// Default pre-binding implementation: every call is a named refusal.
final class _UnboundAgentPlatform implements AgentPlatform {
  const _UnboundAgentPlatform();

  Never _unbound(String operation) {
    throw UnimplementedError(
      'AgentPlatform is not bound on this host — install one of the '
      'zuraffa_agent platform packages (android/ios/macos) and register '
      'it, or set AgentPlatformBinding.instance directly '
      '(operation: $operation)',
    );
  }

  @override
  Future<String?> getAgentHome() => _unbound('getAgentHome');

  @override
  Future<String?> secureRead(String key) => _unbound('secureRead');

  @override
  Future<void> secureWrite(String key, String value) => _unbound('secureWrite');

  @override
  Future<void> secureDelete(String key) => _unbound('secureDelete');
}
