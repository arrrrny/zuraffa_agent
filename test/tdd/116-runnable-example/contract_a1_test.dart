// GENERATED TEST — `zfa tdd gen contract:A1` (issue #1007, contract lane).
//
// behavior_id: contract:A1
// source_criterion: MinimalAgent.run
// kind: contract
// description: MinimalAgent.run() -> Future<MissionResult> (usecase contract)
//
// CONTRACT TEST (issue #1007): this is NOT an implementation test — it
// proves the implementation at `../../../lib/tdd/116-runnable-example/contract_a1_subject.dart`
// satisfies the DECLARED contract above. The body enumerates the
// contract's cases; every case must hold for the contract to be
// satisfied. While the method is deliberately unimplemented the test
// fails through an assertion and `zfa tdd verify-red` reports BLOCKED
// (never RED): a failing contract test blocks the cycle from proceeding
// to GREEN until the implementation satisfies the contract.
library;

// zfa:tdd: contract:A1:hand — hand step completed before first red certification (issue #1411)

import 'package:test/test.dart';
import 'package:zuraffa_agent/tdd/116-runnable-example/contract_a1_subject.dart' as subject;

void main() {
  group('contract:A1 (MinimalAgent.run)', () {
    test('contract:A1 \u2014 MinimalAgent.run() -> Future<MissionResult> (usecase contract)', () {
      // Case 1 of 2 — signature: the declared method
      // `MinimalAgent.run(no parameters) -> Future<MissionResult>` is
      // exposed by the implementation subject.
      final impl = subject.run;
      expect(impl, isNotNull,
          reason: 'MinimalAgent.run must be exposed with the declared '
              'signature `(no parameters) -> Future<MissionResult>`');

      // Case 2 of 2 — implementation: invoking the declared
      // method does not throw UnimplementedError.
      final Object? outcome = _captured(() => impl());
      expect(outcome, isNot(isA<UnimplementedError>()),
          reason: 'MinimalAgent.run is not implemented — the declared '
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

