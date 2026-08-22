/// Artifact Service — minimal interface for artifact storage.
///
/// Provides sink/fetch operations for oversized tool results.
/// Concrete implementations delegated to consuming packages (in-memory, Hive CE, etc.).
library;

import '../domain/entities/artifact_ref/artifact_ref.dart';
import '../domain/entities/artifact/artifact.dart';

/// Configuration for artifact service threshold behavior.
class ArtifactServiceConfig {
  const ArtifactServiceConfig({
    this.thresholdBytes = 262144, // 256 KB default
  });

  /// Byte threshold above which tool results are stored as artifacts
  /// and only a summary + artifactRef enters model context.
  final int thresholdBytes;

  ArtifactServiceConfig copyWith({int? thresholdBytes}) {
    return ArtifactServiceConfig(thresholdBytes: thresholdBytes ?? this.thresholdBytes);
  }
}

/// Result of artifact storage operation.
class ArtifactStoreResult {
  const ArtifactStoreResult({
    required this.ref,
    required this.summarized,
    this.summary,
  });

  final ArtifactRef ref;
  final bool summarized;
  final String? summary;
}

/// Artifact service interface — sink/fetch for artifact data.
abstract class ArtifactService {
  /// Store artifact data, returning an ArtifactRef.
  /// If data exceeds thresholdBytes, returns summarized=true with summary.
  /// If data is within threshold, returns summarized=false with null summary.
  Future<ArtifactStoreResult> store({
    required List<int> data,
    required String mimeType,
  });

  /// Fetch full artifact data by reference.
  Future<Artifact?> fetch(ArtifactRef ref);

  /// Delete artifact by reference.
  Future<void> delete(ArtifactRef ref);

  /// List all stored artifact references.
  Future<List<ArtifactRef>> list();

  /// Get the configured threshold.
  int get thresholdBytes;
}