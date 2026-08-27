/// Artifact entity — stores raw artifact data.
///
/// Used by ArtifactService for oversized tool results.
library;

/// A stored artifact with its reference ID and raw data.
class Artifact {
  const Artifact({
    required this.refId,
    required this.data,
  });

  /// The reference ID linking to the ArtifactRef.
  final String refId;

  /// The raw artifact data.
  final List<int> data;
}
