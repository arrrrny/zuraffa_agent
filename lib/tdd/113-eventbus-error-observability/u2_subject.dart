// GENERATED STUB — `zfa tdd gen U2` (spec 044-test-tdd-generation
// + issue #1259 contract derivation).
//
// behavior_id: U2
// source_criterion: FR-002, EngineEventBus.logSubscriberError
// description: A consumer-provided `onSubscriberError` hook MUST fully
//
// Hand-step (spec 113): publishes through a custom-hook bus with a
// throwing subscriber; the hook's captures land in [u2HookCalls].
// ignore_for_file: non_constant_identifier_names
library;

import 'package:zuraffa_agent/src/engine/engine_event_bus.dart';
import 'package:zuraffa_agent/src/engine/events/engine_event.dart';

/// The custom hook's captures — observable by the paired test.
final List<(Object, EngineEvent)> u2HookCalls = [];

/// Subject for behavior U2 — declared contract:
/// `logSubscriberError(error, event) -> void` (custom-hook variant).
void subject_u2(Object error, EngineEvent event) {
  final bus = EngineEventBus(
    onSubscriberError: (e, ev) => u2HookCalls.add((e, ev)),
  );
  bus.subscribe<TurnStarted>((_) => throw error);
  bus.publish(event);
}
