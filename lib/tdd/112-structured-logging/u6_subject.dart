// GENERATED STUB — `zfa tdd gen U6` (spec 044-test-tdd-generation
// + issue #1259 contract derivation).
//
// behavior_id: U6
// source_criterion: FR-006, AgentLog.document
// description: ARCHITECTURE.md MUST document the logger hierarchy, the
//
// CONTRACT-DERIVED SUBJECT (issue #1259): the signature below is
// derived from the spec's declared Layer Contract:
//
//     document(hierarchy, policy, sinkRecipe) -> void
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
// Declared parameters: hierarchy: hierarchy, policy: policy, sinkrecipe: sinkRecipe (non-existent entity types render as Object? until implemented)
//
// The subject name is derived from the behavior id and is deliberately
// snake_cased — the generator KNOWS the name it emits, so the lint its
// shape provably trips is suppressed here rather than renaming the
// contract surface (issue #1035).
// ignore_for_file: non_constant_identifier_names
library;

import 'package:zuraffa_agent/src/logging/agent_log.dart';

/// Subject for behavior U6 — declared contract:
/// `document(hierarchy, policy, sinkRecipe) -> void`.
///
/// Throws [UnimplementedError] until the real implementation lands.
/// Hand-step (spec 112): the documentation self-check.
void subject_u6(String hierarchy, String policy, String sinkRecipe) =>
    AgentLog.document(
      hierarchy: hierarchy,
      policy: policy,
      sinkRecipe: sinkRecipe,
    );
