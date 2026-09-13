// GENERATED STUB — `zfa tdd gen U4` (spec 044-test-tdd-generation
// + issue #1259 contract derivation).
//
// behavior_id: U4
// source_criterion: FR-004, AgentLog.logger
// description: Emission MUST be safe and cheap before install: no listener
//
// CONTRACT-DERIVED SUBJECT (issue #1259): the signature below is
// derived from the spec's declared Layer Contract:
//
//     logger(subsystem) -> Logger
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
// Declared parameters: subsystem: subsystem (non-existent entity types render as Object? until implemented)
//
// The subject name is derived from the behavior id and is deliberately
// snake_cased — the generator KNOWS the name it emits, so the lint its
// shape provably trips is suppressed here rather than renaming the
// contract surface (issue #1035).
// ignore_for_file: non_constant_identifier_names
library;

import 'package:logging/logging.dart';

import 'package:zuraffa_agent/src/logging/agent_log.dart';

/// Subject for behavior U4 — declared contract:
/// `logger(subsystem) -> Logger`.
///
/// Hand-step (spec 112): the real facade; the test exercises emission
/// safety before install against it.
Logger subject_u4(String subsystem) => AgentLog.logger(subsystem);
