// AgentHomeResolver — pure composition of the agent home layout
// (spec 115 FR-002).

/// The three canonical agent directories under the platform home.
final class AgentHomeLayout {
  /// Sessions live here (JSONL / Hive stores).
  final String sessions;

  /// Episodic memory lives here.
  final String memory;

  /// Run artifacts (recordings, exports) live here.
  final String artifacts;

  const AgentHomeLayout({
    required this.sessions,
    required this.memory,
    required this.artifacts,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgentHomeLayout &&
          runtimeType == other.runtimeType &&
          sessions == other.sessions &&
          memory == other.memory &&
          artifacts == other.artifacts);

  @override
  int get hashCode => Object.hash(sessions, memory, artifacts);

  @override
  String toString() =>
      'AgentHomeLayout(sessions: $sessions, memory: $memory, '
      'artifacts: $artifacts)';
}

/// Composes [AgentHomeLayout] from a platform-provided home.
abstract final class AgentHomeResolver {
  /// The canonical subdirectory names, pinned (spec 115 FR-002).
  static const String sessionsDir = 'sessions';
  static const String memoryDir = 'memory';
  static const String artifactsDir = 'artifacts';

  /// Composes the layout under [home]. Throws [StateError] when [home]
  /// is empty or whitespace — a silent relative path would scatter
  /// agent data into the process working directory.
  static AgentHomeLayout compose(String? home) {
    if (home == null || home.trim().isEmpty) {
      throw StateError(
        'AgentPlatform returned an empty home — the host must provide a '
        'writable home directory for agent data',
      );
    }
    final normalized = _normalize(home);
    return AgentHomeLayout(
      sessions: '$normalized/$sessionsDir',
      memory: '$normalized/$memoryDir',
      artifacts: '$normalized/$artifactsDir',
    );
  }

  /// Trailing separators stripped, backslashes normalized to forward
  /// slashes (the engine's canonical form; hosts map back per platform).
  static String _normalize(String home) {
    var out = home.replaceAll('\\', '/');
    while (out.length > 1 && out.endsWith('/')) {
      out = out.substring(0, out.length - 1);
    }
    return out;
  }
}
