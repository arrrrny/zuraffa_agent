// GENERATED STUB — `zfa tdd gen contract:A12` (issue #1007).
//
// behavior_id: contract:A12
// source_criterion: AgentLog.document
// kind: contract
// target: subject_contract_a12
// description: AgentLog.document(hierarchy, policy, sinkRecipe) -> void (usecase contract)
//
// CONTRACT SEAM (issue #1007): this file is where the declared contract
// `AgentLog.document(dynamic hierarchy, dynamic policy, dynamic sinkRecipe) -> void`
// (usecase contract) gets its implementation. Implement the seam
// below — or wire it to the production method. The paired contract test
// enumerates the contract's cases and stays BLOCKED (never RED) until
// every case is satisfied.
library;

import 'package:zuraffa_agent/src/logging/agent_log.dart';

/// Contract seam for `AgentLog.document(dynamic hierarchy, dynamic policy, dynamic sinkRecipe) -> void`
/// (usecase contract, declared in the spec's Layer Contracts
/// section).
///
/// Throws [UnimplementedError] until the contract is implemented.
// Null-tolerant shim: the mechanical probe passes scaffold nulls
// (zuraffa#1541); real docs self-check covered by U6.
Object? document(dynamic hierarchy, dynamic policy, dynamic sinkRecipe) {
  AgentLog.document(
    hierarchy: hierarchy is String ? hierarchy : 'zuraffa.agent.',
    policy: policy is String ? policy : 'FINE',
    sinkRecipe: sinkRecipe is String ? sinkRecipe : 'ZuraffaLogging.install',
  );
  return null;
}
