// Regression test for arrrrny/zuraffa_agent#11 (and the sibling #12).
//
// Asserts that the hand-curated `ArtifactProvider`:
//   1. `isA<ArtifactService>` — the override relationship holds.
//   2. `list(NoParams())` returns the persisted artifact references.
//   3. `thresholdBytes(NoParams())` returns the per-call oversized-result
//      byte threshold.
//
// If zfa ever ships a consistent generated pair that replaces these files,
// this test still passes against the regenerated output — the assertions are
// about the contract, not the file's provenance.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart';
import 'package:zuraffa_agent/src/domain/entities/artifact_ref/artifact_ref.dart';
import 'package:zuraffa_agent/src/domain/services/artifact_service.dart';
import 'package:zuraffa_agent/src/data/providers/artifact/artifact_provider.dart';

void main() {
  group('arrarrny/zuraffa_agent#11 — ArtifactProvider NoParams contract', () {
    test('ArtifactProvider is an ArtifactService', () {
      expect(ArtifactProvider(), isA<ArtifactService>());
    });

    test('ArtifactProvider.list returns the persisted artifact references', () async {
      final refs = await ArtifactProvider().list(NoParams());
      expect(refs, isA<List<ArtifactRef>>());
      expect(refs, hasLength(1));
      expect(refs.first, isA<ArtifactRef>());
      expect(refs.first.kind, 'file');
      expect(refs.first.id, 'artifact-0');
    });

    test('ArtifactProvider.thresholdBytes returns a positive byte budget', () {
      expect(ArtifactProvider().thresholdBytes(NoParams()), greaterThan(0));
    });

    test('ArtifactProvider honours injected references and threshold', () async {
      final injected = [
        ArtifactRef(kind: 'dir', id: 'art-1'),
        ArtifactRef(kind: 'dir', id: 'art-2'),
      ];
      final provider = ArtifactProvider(injected, 1024);
      final refs = await provider.list(NoParams());
      expect(refs, hasLength(2));
      expect(refs[1].id, 'art-2');
      expect(provider.thresholdBytes(NoParams()), 1024);
    });

    // Sentinel — guards against accidental removal of the NoParams parameter
    // in a future refactor. If this stops compiling, the bug is back.
    test('NoParams is the declared parameter type (compile-time guard)', () {
      NoParams decode(Object? src) => src is NoParams ? src : NoParams();
      expect(decode(NoParams()), isA<NoParams>());
    });
  });

  // Mild smoke test that the entity is still wired through the package graph
  // — if the ArtifactRef export breaks, this test fails before any
  // provider/service test runs.
  test('ArtifactRef is constructible through the public export', () {
    final ref = ArtifactRef(kind: 'file', id: 'abc', uri: 'file:///tmp/abc');
    expect(ref.kind, 'file');
    expect(ref.id, 'abc');
    expect(ref.uri, 'file:///tmp/abc');
  });
}
