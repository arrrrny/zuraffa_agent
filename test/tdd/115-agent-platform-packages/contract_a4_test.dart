// GENERATED TEST — `zfa tdd gen contract:A4` (issue #1007, contract lane).
//
// behavior_id: contract:A4
// source_criterion: AgentPlatform.secureDelete
// kind: contract
// description: AgentPlatform.secureDelete(key) -> Future<void> (usecase contract)
//
// CONTRACT TEST (issue #1007): this is NOT an implementation test — it
// proves the implementation at `../../../lib/tdd/115-agent-platform-packages/contract_a4_subject.dart`
// satisfies the DECLARED contract above. The body enumerates the
// contract's cases; every case must hold for the contract to be
// satisfied. While the method is deliberately unimplemented the test
// fails through an assertion and `zfa tdd verify-red` reports BLOCKED
// (never RED): a failing contract test blocks the cycle from proceeding
// to GREEN until the implementation satisfies the contract.
library;

import 'package:test/test.dart';
import 'package:zuraffa_agent/tdd/115-agent-platform-packages/contract_a4_subject.dart' as subject;

void main() {
  group('contract:A4 (AgentPlatform.secureDelete)', () {
    test('contract:A4 \u2014 AgentPlatform.secureDelete(key) -> Future<void> (usecase contract)', () {
      // Case 1 of 2 — signature: the declared method
      // `AgentPlatform.secureDelete(dynamic key) -> Future<void>` is
      // exposed by the implementation subject.
      final impl = subject.secureDelete;
      expect(impl, isNotNull,
          reason: 'AgentPlatform.secureDelete must be exposed with the declared '
              'signature `(dynamic key) -> Future<void>`');

      // Case 2 of 2 — implementation: invoking the declared
      // method does not throw UnimplementedError.
      final Object? outcome = _captured(() => impl(null));
      expect(outcome, isNot(isA<UnimplementedError>()),
          reason: 'AgentPlatform.secureDelete is not implemented — the declared '
              'contract is unsatisfied, so the cycle is BLOCKED and cannot '
              'proceed to GREEN (issue #1007)');
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

