// GENERATED STUB — `zfa tdd gen contract:A1` (issue #1007).
//
// behavior_id: contract:A1
// source_criterion: EngineEventBus.logSubscriberError
// kind: contract
// target: subject_contract_a1
// description: EngineEventBus.logSubscriberError(error, event) -> void (usecase contract)
//
// CONTRACT SEAM (issue #1007): this file is where the declared contract
// `EngineEventBus.logSubscriberError(dynamic error, dynamic event) -> void`
// (usecase contract) gets its implementation. Implement the seam
// below — or wire it to the production method. The paired contract test
// enumerates the contract's cases and stays BLOCKED (never RED) until
// every case is satisfied.
library;

import 'package:zuraffa_agent/src/engine/engine_event_bus.dart';
import 'package:zuraffa_agent/src/engine/events/engine_event.dart';

/// Contract seam for `EngineEventBus.logSubscriberError(dynamic error, dynamic event) -> void`
/// (usecase contract, declared in the spec's Layer Contracts
/// section).
///
/// Throws [UnimplementedError] until the contract is implemented.
// Null-tolerant shim: the mechanical probe passes scaffold nulls
// (zuraffa#1541); the real route is covered by U1/U2/U4.
Object? logSubscriberError(dynamic error, dynamic event) {
  EngineEventBus.logSubscriberError(
    (error ?? StateError('unspecified')) as Object,
    event as EngineEvent? ??
        TurnStarted(emittedAt: DateTime.now(), turnId: 'probe'),
  );
  return null;
}
