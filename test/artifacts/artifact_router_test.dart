// ArtifactRouter tests (FR-007, SC-007, contracts/artifact-router.md).
//
// Oversized results are persisted via AgentArtifactPort and replaced with a
// summary + AgentArtifactRef; the result is never silently truncated into the
// model. A missing port yields a typed missingArtifactPort outcome.
import 'package:test/test.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

void main() {
  group('ArtifactRouter', () {
    test('an under-threshold result stays inline', () async {
      final port = InMemoryAgentArtifactPort();
      final router = ArtifactRouter(port: port, threshold: 100);
      final outcome = await router.route('t1', [1, 2, 3]);
      expect(outcome, isA<InlineArtifact>());
      expect((outcome as InlineArtifact).bytes, [1, 2, 3]);
      expect(await port.resolve('artifact-0'), isNull);
    });

    test('an over-threshold result is stored and referenced', () async {
      final port = InMemoryAgentArtifactPort();
      final router = ArtifactRouter(port: port, threshold: 4);
      final outcome = await router.route('t1', [1, 2, 3, 4, 5]);
      expect(outcome, isA<ArtifactRefOutcome>());
      final ref = (outcome as ArtifactRefOutcome).ref;
      expect(ref.kind, 'oversized-result');
      expect(ref.byteSize, 5);
      expect(await port.resolve(ref.id), [1, 2, 3, 4, 5]);
    });

    test('a missing port yields typed missingArtifactPort', () async {
      final router = ArtifactRouter(port: null, threshold: 4);
      final outcome = await router.route('t1', [1, 2, 3, 4, 5]);
      expect(outcome, isA<MissingArtifactPortOutcome>());
    });
  });
}
