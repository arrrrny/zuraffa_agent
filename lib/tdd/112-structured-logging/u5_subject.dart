// GENERATED STUB — `zfa tdd gen U5` (spec 044-test-tdd-generation
// + issue #1259 contract derivation).
//
// behavior_id: U5
// source_criterion: FR-005, AgentLog.retryWarning
// description: The first adoption sites MUST ship with this spec: the LLM
//
// CONTRACT-DERIVED SUBJECT (issue #1259): the signature below is
// derived from the spec's declared Layer Contract:
//
//     retryWarning(attempt, delay, error) -> void
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
// Declared parameters: attempt: attempt, delay: delay, error: error (non-existent entity types render as Object? until implemented)
//
// The subject name is derived from the behavior id and is deliberately
// snake_cased — the generator KNOWS the name it emits, so the lint its
// shape provably trips is suppressed here rather than renaming the
// contract surface (issue #1035).
// ignore_for_file: non_constant_identifier_names
library;

import 'package:logging/logging.dart';

import 'package:zuraffa_agent/src/logging/agent_log.dart';

/// Subject for behavior U5 — declared contract:
/// `retryWarning(attempt, delay, error) -> void`.
///
/// Throws [UnimplementedError] until the real implementation lands.
/// Hand-step (spec 112): the real resilience-emission helper.
void subject_u5(int attempt, Duration delay, Object error) =>
    AgentLog.retryWarning(attempt: attempt, delay: delay, error: error);
