/// In-Memory Artifact Store — development/testing implementation of ArtifactService.
///
/// Stores artifacts in a simple Map. Not suitable for production persistence.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' show min;

import 'package:uuid/uuid.dart';

import '../domain/entities/artifact/artifact.dart';
import '../domain/entities/artifact_ref/artifact_ref.dart';
import 'artifact_service.dart';

/// In-memory implementation of [ArtifactService].
class InMemoryArtifactStore implements ArtifactService {
  InMemoryArtifactStore({ArtifactServiceConfig? config})
      : _config = config ?? const ArtifactServiceConfig(),
        _store = <String, Artifact>{},
        _uuid = const Uuid();

  final ArtifactServiceConfig _config;
  final Map<String, Artifact> _store;
  final Uuid _uuid;

  @override
  int get thresholdBytes => _config.thresholdBytes;

  @override
  Future<ArtifactStoreResult> store({
    required List<int> data,
    required String mimeType,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final sizeBytes = data.length;

    final ref = ArtifactRef(
      id: id,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      createdAt: now,
    );

    final artifact = Artifact(refId: id, data: data);
    _store[id] = artifact;

    final exceeded = sizeBytes > _config.thresholdBytes;
    String? summary;
    if (exceeded) {
      summary = _summarize(data, mimeType, sizeBytes);
    }

    return ArtifactStoreResult(
      ref: ref,
      summarized: exceeded,
      summary: summary,
    );
  }

  @override
  Future<Artifact?> fetch(ArtifactRef ref) async {
    return _store[ref.id];
  }

  @override
  Future<void> delete(ArtifactRef ref) async {
    _store.remove(ref.id);
  }

  @override
  Future<List<ArtifactRef>> list() async {
    return _store.values
        .map((a) => ArtifactRef(
              id: a.refId,
              mimeType: 'application/octet-stream', // Not stored in artifact, would need to be tracked
              sizeBytes: a.data.length,
              createdAt: DateTime.now(), // Not stored, would need to be tracked
            ))
        .toList();
  }

  String _summarize(List<int> data, String mimeType, int sizeBytes) {
    final previewLength = min(data.length, 512);
    final preview = utf8.decode(data.sublist(0, previewLength), allowMalformed: true);
    final truncated = data.length > previewLength ? '... (truncated)' : '';

    return '''Artifact Summary:
- ID: ${_uuid.v4()}
- MIME Type: $mimeType
- Size: $sizeBytes bytes (${_formatBytes(sizeBytes)})
- Preview: $preview$truncated
- Full body available via artifact fetch.''';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}