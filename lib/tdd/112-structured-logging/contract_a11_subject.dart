// GENERATED STUB — `zfa tdd gen contract:A11` (issue #1007).
//
// behavior_id: contract:A11
// source_criterion: AgentLog.missionInfo
// kind: contract
// target: subject_contract_a11
// description: AgentLog.missionInfo(missionId, outcome) -> void (usecase contract)
//
// CONTRACT SEAM (issue #1007): this file is where the declared contract
// `AgentLog.missionInfo(dynamic missionId, dynamic outcome) -> void`
// (usecase contract) gets its implementation. Implement the seam
// below — or wire it to the production method. The paired contract test
// enumerates the contract's cases and stays BLOCKED (never RED) until
// every case is satisfied.
library;

import 'package:zuraffa_agent/src/logging/agent_log.dart';

/// Contract seam for `AgentLog.missionInfo(dynamic missionId, dynamic outcome) -> void`
/// (usecase contract, declared in the spec's Layer Contracts
/// section).
///
/// Throws [UnimplementedError] until the contract is implemented.
// Null-tolerant shim: the mechanical probe passes scaffold nulls
// (zuraffa#1541); real lifecycle emission covered by the A6 mission
// fixture and the MissionRunner adoption site.
Object? missionInfo(dynamic missionId, dynamic outcome) {
  AgentLog.missionInfo(
    missionId: missionId is String ? missionId : 'unspecified',
    outcome: outcome is String ? outcome : 'unspecified',
  );
  return null;
}
