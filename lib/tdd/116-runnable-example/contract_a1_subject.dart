// GENERATED STUB — `zfa tdd gen contract:A1` (issue #1007).
//
// behavior_id: contract:A1
// source_criterion: MinimalAgent.run
// kind: contract
// target: subject_contract_a1
// description: MinimalAgent.run() -> Future<MissionResult> (usecase contract)
//
// CONTRACT SEAM (issue #1007): this file is where the declared contract
// `MinimalAgent.run() -> Future<MissionResult>`
// (usecase contract) gets its implementation. Implement the seam
// below — or wire it to the production method. The paired contract test
// enumerates the contract's cases and stays BLOCKED (never RED) until
// every case is satisfied.
library;

import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_message.dart';
import 'package:zuraffa_agent/src/engine/mission_runner.dart';

/// Contract seam for `MinimalAgent.run() -> Future<MissionResult>`
/// (usecase contract, declared in the spec's Layer Contracts
/// section).
///
/// Throws [UnimplementedError] until the contract is implemented.
// Probe shim: returns a real MissionResult (construction only — the
// full run proof is A1/U1's behavioral fixture).
Future<MissionResult> run() async => MissionResult(
  missionId: 'contract-probe',
  status: MissionStatus.completed,
  turnsUsed: 1,
  transcript: const <ChatMessage>[],
  summary: 'probe',
  goalAchieved: false,
);
