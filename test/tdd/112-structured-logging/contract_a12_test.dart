// GENERATED TEST — `zfa tdd gen contract:A12` (issue #1007, contract lane).
//
// behavior_id: contract:A12
// source_criterion: AgentLog.document
// kind: contract
// description: AgentLog.document(hierarchy, policy, sinkRecipe) -> void (usecase contract)
//
// CONTRACT TEST (issue #1007): this is NOT an implementation test — it
// proves the implementation at `../../../lib/tdd/112-structured-logging/contract_a12_subject.dart`
// satisfies the DECLARED contract above. The body enumerates the
// contract's cases; every case must hold for the contract to be
// satisfied. While the method is deliberately unimplemented the test
// fails through an assertion and `zfa tdd verify-red` reports BLOCKED
// (never RED): a failing contract test blocks the cycle from proceeding
// to GREEN until the implementation satisfies the contract.
library;

// zfa:tdd: contract:A12:hand — hand step completed before first red certification (issue #1411)

import 'package:test/test.dart';

import 'package:zuraffa_agent/tdd/112-structured-logging/contract_a12_subject.dart' as direct;
import 'package:zuraffa_agent/tdd/112-structured-logging/contract_a12_subject.dart' as subject;

void main() {
  group('contract:A12 (AgentLog.document)', () {
    test('contract:A12 \u2014 AgentLog.document(hierarchy, policy, sinkRecipe) -> void (usecase contract)', () {
      // Case 1 of 2 — signature: the declared method
      // `AgentLog.document(dynamic hierarchy, dynamic policy, dynamic sinkRecipe) -> void` is
      // exposed by the implementation subject.
      final impl = subject.document;
      expect(impl, isNotNull,
          reason: 'AgentLog.document must be exposed with the declared '
              'signature `(dynamic hierarchy, dynamic policy, dynamic sinkRecipe) -> void`');

      // Case 2 of 2 — implementation: invoking the declared
      // method does not throw UnimplementedError.
      final Object? outcome = _captured(() => impl(null, null, null));
      expect(outcome, isNot(isA<UnimplementedError>()),
          reason: 'AgentLog.document is not implemented — the declared '
              'contract is unsatisfied, so the cycle is BLOCKED and cannot '
              'proceed to GREEN (issue #1007)');
      // Call-through proof: the shim reaches the real self-check — an
      // empty section is REFUSED, a covered one passes.
      expect(
        () => subject.document(' ', 'FINE', 'install'),
        throwsArgumentError,
      );
      direct.document('hierarchy', 'policy', 'recipe');
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

