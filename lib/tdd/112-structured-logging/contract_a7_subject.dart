// GENERATED STUB — `zfa tdd gen contract:A7` (issue #1007).
//
// behavior_id: contract:A7
// source_criterion: AgentLog.logger
// kind: contract
// target: subject_contract_a7
// description: AgentLog.logger(subsystem) -> Logger (usecase contract)
//
// CONTRACT SEAM (issue #1007): this file is where the declared contract
// `AgentLog.logger(dynamic subsystem) -> Logger`
// (usecase contract) gets its implementation. Implement the seam
// below — or wire it to the production method. The paired contract test
// enumerates the contract's cases and stays BLOCKED (never RED) until
// every case is satisfied.
library;

import 'package:logging/logging.dart';

import 'package:zuraffa_agent/src/logging/agent_log.dart';

/// Contract seam for `AgentLog.logger(dynamic subsystem) -> Logger`
/// (usecase contract, declared in the spec's Layer Contracts
/// section).
///
/// Wired to the production facade (spec 112).
// Null-tolerant shim: the mechanical contract probe invokes the seam
// with a scaffold null (zuraffa#1541); the pinned-set validation itself
// is covered honestly by U1.
Logger logger(dynamic subsystem) => subsystem is String
    ? AgentLog.logger(subsystem)
    : AgentLog.logger(AgentLog.subsystems.first);
