// GENERATED TEST — `zfa tdd gen contract:A10` (issue #1007, contract lane).
//
// behavior_id: contract:A10
// source_criterion: AgentLog.retryWarning
// kind: contract
// description: AgentLog.retryWarning(attempt, delay, error) -> void (usecase contract)
//
// CONTRACT TEST (issue #1007): this is NOT an implementation test — it
// proves the implementation at `../../../lib/tdd/112-structured-logging/contract_a10_subject.dart`
// satisfies the DECLARED contract above. The body enumerates the
// contract's cases; every case must hold for the contract to be
// satisfied. While the method is deliberately unimplemented the test
// fails through an assertion and `zfa tdd verify-red` reports BLOCKED
// (never RED): a failing contract test blocks the cycle from proceeding
// to GREEN until the implementation satisfies the contract.
library;

// zfa:tdd: contract:A10:hand — hand step completed before first red certification (issue #1411)

import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'package:zuraffa_agent/src/logging/agent_log.dart';
import 'package:zuraffa_agent/src/logging/memory_log_sink.dart';
import 'package:zuraffa_agent/tdd/112-structured-logging/contract_a10_subject.dart' as subject;

void main() {
  group('contract:A10 (AgentLog.retryWarning)', () {
    test('contract:A10 \u2014 AgentLog.retryWarning(attempt, delay, error) -> void (usecase contract)', () {
      // Case 1 of 2 — signature: the declared method
      // `AgentLog.retryWarning(dynamic attempt, dynamic delay, dynamic error) -> void` is
      // exposed by the implementation subject.
      final impl = subject.retryWarning;
      expect(impl, isNotNull,
          reason: 'AgentLog.retryWarning must be exposed with the declared '
              'signature `(dynamic attempt, dynamic delay, dynamic error) -> void`');

      // Case 2 of 2 — implementation: invoking the declared
      // method does not throw UnimplementedError.
      final Object? outcome = _captured(() => impl(null, null, null));
      expect(outcome, isNot(isA<UnimplementedError>()),
          reason: 'AgentLog.retryWarning is not implemented — the declared '
              'contract is unsatisfied, so the cycle is BLOCKED and cannot '
              'proceed to GREEN (issue #1007)');
      // Call-through proof: the shim reaches the real resilience helper.
      ZuraffaLogging.reset();
      addTearDown(ZuraffaLogging.reset);
      final sink = MemoryLogSink();
      ZuraffaLogging.install(level: Level.WARNING, onRecord: sink.add);
      subject.retryWarning(2, const Duration(milliseconds: 300),
          StateError('deadline'));
      final record = sink.firstWhereMessage('retry scheduled');
      expect(record, isNotNull);
      expect(record!.message, contains('attempt=2'));
      expect(record.message, contains('delay=300ms'));
    });
  });
}

/// Captures an [UnimplementedError] thrown by an unimplemented contract
/// seam (or a scaffold placeholder argument) as the assertion's actual
/// value, so the blocked state fails through an assertion (never an
/// uncaught error).
Object? _captured(Object? Function() invoke) {
  try {
    return invoke();
  } on UnimplementedError catch (error) {
    return error;
  }
}

