// GENERATED STUB — `zfa tdd gen contract:A3` (issue #1007).
//
// behavior_id: contract:A3
// source_criterion: EngineEventBus.subscriberErrorEvent
// kind: contract
// target: subject_contract_a3
// description: EngineEventBus.subscriberErrorEvent(error, event) -> EngineEventSubscriberError (usecase contract)
//
// CONTRACT SEAM (issue #1007): this file is where the declared contract
// `EngineEventBus.subscriberErrorEvent(dynamic error, dynamic event) -> EngineEventSubscriberError`
// (usecase contract) gets its implementation. Implement the seam
// below — or wire it to the production method. The paired contract test
// enumerates the contract's cases and stays BLOCKED (never RED) until
// every case is satisfied.
library;

import 'package:zuraffa_agent/src/engine/engine_event_bus.dart';
import 'package:zuraffa_agent/src/engine/events/engine_event.dart';

/// Contract seam for `EngineEventBus.subscriberErrorEvent(dynamic error, dynamic event) -> EngineEventSubscriberError`
/// (usecase contract, declared in the spec's Layer Contracts
/// section).
///
/// Throws [UnimplementedError] until the contract is implemented.
// Null-tolerant shim: the mechanical probe passes scaffold nulls
// (zuraffa#1541); the real factory + guard are covered by U3.
Object? subscriberErrorEvent(dynamic error, dynamic event) =>
    EngineEventBus.subscriberErrorEvent(
      (error ?? StateError('unspecified')) as Object,
      event as EngineEvent? ??
          TurnStarted(emittedAt: DateTime.now(), turnId: 'probe'),
    );
