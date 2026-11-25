/// Host-injection port for artifacts / oversized results (FR-006).
///
/// `store` returns the Zorphy-generated [AgentArtifactDescriptor] entity so the
/// host persists it; the wrapper stores nothing. `resolve` returns the bytes or
/// `null` for an unknown id. Tests use [InMemoryAgentArtifactPort].
library;

import '../domain/entities/agent_artifact_descriptor/agent_artifact_descriptor.dart';

/// Persists and resolves binary artifacts on behalf of the host.
abstract class AgentArtifactPort {
  Future<AgentArtifactDescriptor> store(String kind, List<int> bytes);
  Future<List<int>?> resolve(String id);
}

/// Pure-Dart in-memory [AgentArtifactPort].
class InMemoryAgentArtifactPort implements AgentArtifactPort {
  final Map<String, List<int>> _bytes = {};
  int _seq = 0;

  @override
  Future<AgentArtifactDescriptor> store(String kind, List<int> bytes) async {
    final id = 'artifact-${_seq++}';
    _bytes[id] = List.unmodifiable(bytes);
    return AgentArtifactDescriptor(id: id, kind: kind, byteCount: bytes.length);
  }

  @override
  Future<List<int>?> resolve(String id) async => _bytes[id];
}
