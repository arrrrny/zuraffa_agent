// GENERATED TEST — `zfa tdd gen contract:A8` (issue #1007, contract lane).
//
// behavior_id: contract:A8
// source_criterion: AgentLog.install
// kind: contract
// description: AgentLog.install(level, onRecord) -> void (usecase contract)
//
// CONTRACT TEST (issue #1007): this is NOT an implementation test — it
// proves the implementation at `../../../lib/tdd/112-structured-logging/contract_a8_subject.dart`
// satisfies the DECLARED contract above. The body enumerates the
// contract's cases; every case must hold for the contract to be
// satisfied. While the method is deliberately unimplemented the test
// fails through an assertion and `zfa tdd verify-red` reports BLOCKED
// (never RED): a failing contract test blocks the cycle from proceeding
// to GREEN until the implementation satisfies the contract.
library;

// zfa:tdd: contract:A8:hand — hand step completed before first red certification (issue #1411)

import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'package:zuraffa_agent/src/logging/agent_log.dart';
import 'package:zuraffa_agent/src/logging/memory_log_sink.dart';
import 'package:zuraffa_agent/tdd/112-structured-logging/contract_a8_subject.dart' as subject;

void main() {
  group('contract:A8 (AgentLog.install)', () {
    test('contract:A8 \u2014 AgentLog.install(level, onRecord) -> void (usecase contract)', () {
      // Case 1 of 2 — signature: the declared method
      // `AgentLog.install(dynamic level, dynamic onRecord) -> void` is
      // exposed by the implementation subject.
      final impl = subject.install;
      expect(impl, isNotNull,
          reason: 'AgentLog.install must be exposed with the declared '
              'signature `(dynamic level, dynamic onRecord) -> void`');

      // Case 2 of 2 — implementation: invoking the declared
      // method does not throw UnimplementedError.
      final Object? outcome = _captured(() => impl(null, null));
      expect(outcome, isNot(isA<UnimplementedError>()),
          reason: 'AgentLog.install is not implemented — the declared '
              'contract is unsatisfied, so the cycle is BLOCKED and cannot '
              'proceed to GREEN (issue #1007)');
      // Call-through proof: the shim reaches the real facade.
      ZuraffaLogging.reset();
      addTearDown(ZuraffaLogging.reset);
      final sink = MemoryLogSink();
      subject.install(Level.WARNING, sink.add);
      AgentLog.llm.info('filtered');
      AgentLog.session.warning('delivered');
      expect(sink.length, 1);
      expect(sink.records.single.message, 'delivered');
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

