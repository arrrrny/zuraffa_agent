// GENERATED STUB — `zfa tdd gen U1` (spec 044-test-tdd-generation
// + issue #1259 contract derivation).
//
// behavior_id: U1
// source_criterion: FR-001, EngineEventBus.logSubscriberError
// description: With no consumer hook installed, the bus MUST route
//
// CONTRACT-DERIVED SUBJECT (issue #1259): the signature below is
// derived from the spec's declared Layer Contract:
//
//     logSubscriberError(error, event) -> void
//
// The declared request and result types are preserved above. A
// declared type whose entity does not exist yet renders as `Object?`
// so the stub compiles cleanly (FR-011) — the degradation is
// unconditional ONLY for entities that do not exist on disk; replace
// it with the declared type once the entity lands. This is a MINIMAL
// COMPILABLE STUB: it does NOT satisfy the behavior — the paired test
// fails on first execution (honest red). Replace this stub body with
// the real implementation of the declared contract to make the test
// pass.
// Declared parameters: error: error, event: event (non-existent entity types render as Object? until implemented)
//
// The subject name is derived from the behavior id and is deliberately
// snake_cased — the generator KNOWS the name it emits, so the lint its
// shape provably trips is suppressed here rather than renaming the
// contract surface (issue #1035).
// ignore_for_file: non_constant_identifier_names
library;

import 'package:zuraffa_agent/src/engine/engine_event_bus.dart';
import 'package:zuraffa_agent/src/engine/events/engine_event.dart';

/// Subject for behavior U1 — declared contract:
/// `logSubscriberError(error, event) -> void`.
///
/// Throws [UnimplementedError] until the real implementation lands.
/// Hand-step (spec 113): the real default route.
void subject_u1(Object error, EngineEvent event) =>
    EngineEventBus.logSubscriberError(error, event);
