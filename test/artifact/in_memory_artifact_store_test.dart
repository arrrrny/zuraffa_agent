// Tests for InMemoryArtifactStore — Spec 003: Tools & MCP (FR-005)
//
// Covers:
// - Artifact storage and retrieval
// - Threshold-based summarization
// - Delete and list operations

import 'dart:convert';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/artifact/artifact_service.dart';
import 'package:zuraffa_agent/src/artifact/in_memory_artifact_store.dart';
import 'package:zuraffa_agent/src/domain/entities/artifact_ref/artifact_ref.dart';

void main() {
  late InMemoryArtifactStore store;

  setUp(() {
    store = InMemoryArtifactStore();
  });

  group('InMemoryArtifactStore - Store', () {
    test('stores data and returns non-summarized result within threshold', () async {
      final data = utf8.encode('small result');
      final result = await store.store(
        data: data,
        mimeType: 'text/plain',
      );

      expect(result.summarized, isFalse);
      expect(result.summary, isNull);
      expect(result.ref.id, isNotEmpty);
      expect(result.ref.mimeType, 'text/plain');
      expect(result.ref.sizeBytes, data.length);
    });

    test('summarizes data exceeding threshold', () async {
      // Create data exceeding default 256KB threshold
      final largeData = List<int>.filled(300 * 1024, 65); // 300 KB of 'A'
      final result = await store.store(
        data: largeData,
        mimeType: 'application/octet-stream',
      );

      expect(result.summarized, isTrue);
      expect(result.summary, isNotNull);
      expect(result.summary, contains('Artifact Summary'));
      expect(result.summary, contains('300'));
      expect(result.ref.sizeBytes, largeData.length);
    });

    test('respects custom threshold', () async {
      final customStore = InMemoryArtifactStore(
        config: const ArtifactServiceConfig(thresholdBytes: 100),
      );

      final data = utf8.encode('a' * 200); // 200 bytes, exceeds 100 byte threshold
      final result = await customStore.store(
        data: data,
        mimeType: 'text/plain',
      );

      expect(result.summarized, isTrue);
      expect(result.summary, isNotNull);
    });
  });

  group('InMemoryArtifactStore - Fetch', () {
    test('fetches stored artifact by ref', () async {
      final data = utf8.encode('test data');
      final result = await store.store(
        data: data,
        mimeType: 'text/plain',
      );

      final artifact = await store.fetch(result.ref);

      expect(artifact, isNotNull);
      expect(artifact!.data, equals(data));
    });

    test('returns null for non-existent ref', () async {
      final artifact = await store.fetch(
        ArtifactRef(
          id: 'non-existent',
          mimeType: 'text/plain',
          sizeBytes: 0,
          createdAt: DateTime.now(),
        ),
      );

      expect(artifact, isNull);
    });
  });

  group('InMemoryArtifactStore - Delete', () {
    test('deletes stored artifact', () async {
      final data = utf8.encode('to be deleted');
      final result = await store.store(
        data: data,
        mimeType: 'text/plain',
      );

      await store.fetch(result.ref); // Verify it exists
      await store.delete(result.ref);
      final artifact = await store.fetch(result.ref);

      expect(artifact, isNull);
    });
  });

  group('InMemoryArtifactStore - List', () {
    test('lists all stored artifacts', () async {
      await store.store(data: utf8.encode('a'), mimeType: 'text/plain');
      await store.store(data: utf8.encode('b'), mimeType: 'text/plain');

      final refs = await store.list();

      expect(refs, hasLength(2));
    });

    test('returns empty list when no artifacts', () async {
      final refs = await store.list();

      expect(refs, isEmpty);
    });
  });

  group('InMemoryArtifactStore - Threshold', () {
    test('reports configured threshold', () {
      expect(store.thresholdBytes, 262144); // 256 KB default
    });

    test('reports custom threshold', () {
      final customStore = InMemoryArtifactStore(
        config: const ArtifactServiceConfig(thresholdBytes: 1024),
      );

      expect(customStore.thresholdBytes, 1024);
    });
  });
}
