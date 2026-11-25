// Contract-parity suite (FR-009, SC-009, contracts/artifact-router.md).
//
// The SAME contract function runs against any AgentArtifactPort — the
// pure-Dart in-memory adapter here and a host's production adapter — with no
// per-adapter branching. A host runs `runArtifactRouterContract` against its
// own port to prove parity.
import 'package:test/test.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

/// The artifact-router contract, parameterized only by the port under test.
Future<void> runArtifactRouterContract(
  AgentArtifactPort port,
  int threshold,
) async {
  final router = ArtifactRouter(port: port, threshold: threshold);

  final inline = await router.route('t', [1, 2, 3]);
  expect(inline, isA<InlineArtifact>());
  expect((inline as InlineArtifact).bytes, [1, 2, 3]);

  final over = await router.route('t', List<int>.filled(threshold + 1, 7));
  expect(over, isA<ArtifactRefOutcome>());
  final ref = (over as ArtifactRefOutcome).ref;
  expect(ref.byteSize, threshold + 1);
  expect(await port.resolve(ref.id), List<int>.filled(threshold + 1, 7));
}

void main() {
  test('in-memory AgentArtifactPort satisfies the contract', () async {
    await runArtifactRouterContract(InMemoryAgentArtifactPort(), 4);
  });
}
