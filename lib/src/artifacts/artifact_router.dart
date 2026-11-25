/// Routes oversized tool results to the host's [AgentArtifactPort] and replaces
/// the inline bytes with a reference (FR-007, SC-007,
/// contracts/artifact-router.md).
///
/// The router never truncates into the model: an over-threshold result is
/// persisted and the model sees an [AgentArtifactRef] summary. A missing port
/// yields a typed [MissingArtifactPortOutcome] rather than silent truncation.
library;

import '../ports/agent_artifact_port.dart';

/// An opaque reference to a stored artifact the model sees instead of bytes.
class AgentArtifactRef {
  final String id;
  final String kind;
  final int byteSize;
  final String summary;

  const AgentArtifactRef({
    required this.id,
    required this.kind,
    required this.byteSize,
    required this.summary,
  });
}

/// The outcome of routing a tool result.
sealed class ArtifactRoutingOutcome {
  const ArtifactRoutingOutcome();
}

/// The result was under the threshold and stays inline.
class InlineArtifact extends ArtifactRoutingOutcome {
  final List<int> bytes;
  const InlineArtifact(this.bytes);
}

/// The result was over the threshold; the model sees [ref], bytes are stored.
class ArtifactRefOutcome extends ArtifactRoutingOutcome {
  final AgentArtifactRef ref;
  const ArtifactRefOutcome(this.ref);
}

/// No [AgentArtifactPort] was injected; the result is not truncated.
class MissingArtifactPortOutcome extends ArtifactRoutingOutcome {
  final int byteSize;
  const MissingArtifactPortOutcome(this.byteSize);
}

/// Persists oversized results and returns inline content or a reference.
class ArtifactRouter {
  final AgentArtifactPort? _port;
  final int threshold;

  ArtifactRouter({required AgentArtifactPort? port, required this.threshold})
    : _port = port;

  /// Routes [bytes] for [toolName]. The kind recorded is `oversized-result`.
  Future<ArtifactRoutingOutcome> route(String toolName, List<int> bytes) async {
    if (bytes.length <= threshold) return InlineArtifact(bytes);
    final port = _port;
    if (port == null) return MissingArtifactPortOutcome(bytes.length);
    final descriptor = await port.store('oversized-result', bytes);
    return ArtifactRefOutcome(
      AgentArtifactRef(
        id: descriptor.id,
        kind: descriptor.kind,
        byteSize: descriptor.byteCount,
        summary: 'oversized $toolName result (${bytes.length} bytes)',
      ),
    );
  }
}
