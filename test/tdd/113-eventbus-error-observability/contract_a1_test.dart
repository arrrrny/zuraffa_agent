// GENERATED TEST — `zfa tdd gen contract:A1` (issue #1007, contract lane).
//
// behavior_id: contract:A1
// source_criterion: EngineEventBus.logSubscriberError
// kind: contract
// description: EngineEventBus.logSubscriberError(error, event) -> void (usecase contract)
//
// CONTRACT TEST (issue #1007): this is NOT an implementation test — it
// proves the implementation at `../../../lib/tdd/113-eventbus-error-observability/contract_a1_subject.dart`
// satisfies the DECLARED contract above. The body enumerates the
// contract's cases; every case must hold for the contract to be
// satisfied. While the method is deliberately unimplemented the test
// fails through an assertion and `zfa tdd verify-red` reports BLOCKED
// (never RED): a failing contract test blocks the cycle from proceeding
// to GREEN until the implementation satisfies the contract.
library;

// zfa:tdd: contract:A1:hand — hand step completed before first red certification (issue #1411)

import 'package:test/test.dart';
import 'package:zuraffa_agent/tdd/113-eventbus-error-observability/contract_a1_subject.dart' as subject;

void main() {
  group('contract:A1 (EngineEventBus.logSubscriberError)', () {
    test('contract:A1 \u2014 EngineEventBus.logSubscriberError(error, event) -> void (usecase contract)', () {
      // Case 1 of 2 — signature: the declared method
      // `EngineEventBus.logSubscriberError(dynamic error, dynamic event) -> void` is
      // exposed by the implementation subject.
      final impl = subject.logSubscriberError;
      expect(impl, isNotNull,
          reason: 'EngineEventBus.logSubscriberError must be exposed with the declared '
              'signature `(dynamic error, dynamic event) -> void`');

      // Case 2 of 2 — implementation: invoking the declared
      // method does not throw UnimplementedError.
      final Object? outcome = _captured(() => impl(null, null));
      expect(outcome, isNot(isA<UnimplementedError>()),
          reason: 'EngineEventBus.logSubscriberError is not implemented — the declared '
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

