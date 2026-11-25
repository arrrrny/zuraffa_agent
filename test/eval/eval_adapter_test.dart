// EvalAdapter tests (FR-007, SC-007, contracts/eval-adapter.md).
//
// Eval/cassette replay delegates to pi-evals (an EvalDelegate); the wrapper
// records an AgentEvaluationReport row per case on top. With no delegate the
// adapter fails with a typed evalUnavailable outcome and ships no second eval
// engine.
import 'package:test/test.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

void main() {
  group('EvalAdapter', () {
    test('run records a report row per case via telemetry', () async {
      final telemetry = InMemoryAgentTelemetryPort();
      final adapter = EvalAdapter(
        delegate: InMemoryEvalDelegate(
          results: const [
            EvalCaseResult(
              caseName: 'c1',
              passed: true,
              transcriptRef: 'ref-1',
            ),
            EvalCaseResult(
              caseName: 'c2',
              passed: false,
              transcriptRef: 'ref-2',
            ),
          ],
        ),
        telemetry: telemetry,
      );
      final run = await adapter.run(const EvalSuite('suite-a'));
      expect(run.reports, hasLength(2));
      final evalEvents = telemetry.events
          .where((e) => e.name == 'agent.eval')
          .toList();
      expect(evalEvents, hasLength(2));
      expect(evalEvents.first.attributes['suite'], 'suite-a');
    });

    test('a missing delegate yields typed evalUnavailable', () async {
      final telemetry = InMemoryAgentTelemetryPort();
      final adapter = EvalAdapter(delegate: null, telemetry: telemetry);
      expect(
        () => adapter.run(const EvalSuite('s')),
        throwsA(isA<EvalUnavailableException>()),
      );
      expect(
        telemetry.events.any(
          (e) => e.attributes['outcome'] == 'evalUnavailable',
        ),
        isTrue,
      );
    });

    test('a replay failure surfaces a typed cassetteError report', () async {
      final telemetry = InMemoryAgentTelemetryPort();
      final adapter = EvalAdapter(
        delegate: _ThrowingEvalDelegate(),
        telemetry: telemetry,
      );
      expect(
        () => adapter.run(const EvalSuite('s'), cassette: 'bad'),
        throwsA(isA<CassetteException>()),
      );
      expect(
        telemetry.events.any((e) => e.attributes['outcome'] == 'cassetteError'),
        isTrue,
      );
    });
  });
}

class _ThrowingEvalDelegate implements EvalDelegate {
  @override
  Future<List<EvalCaseResult>> run(EvalSuite suite, {String? cassette}) =>
      throw const CassetteException('cannot replay');
}
