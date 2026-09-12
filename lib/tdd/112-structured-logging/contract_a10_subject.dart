// GENERATED STUB — `zfa tdd gen contract:A10` (issue #1007).
//
// behavior_id: contract:A10
// source_criterion: AgentLog.retryWarning
// kind: contract
// target: subject_contract_a10
// description: AgentLog.retryWarning(attempt, delay, error) -> void (usecase contract)
//
// CONTRACT SEAM (issue #1007): this file is where the declared contract
// `AgentLog.retryWarning(dynamic attempt, dynamic delay, dynamic error) -> void`
// (usecase contract) gets its implementation. Implement the seam
// below — or wire it to the production method. The paired contract test
// enumerates the contract's cases and stays BLOCKED (never RED) until
// every case is satisfied.
library;

import 'package:logging/logging.dart';

import 'package:zuraffa_agent/src/logging/agent_log.dart';

/// Contract seam for `AgentLog.retryWarning(dynamic attempt, dynamic delay, dynamic error) -> void`
/// (usecase contract, declared in the spec's Layer Contracts
/// section).
///
/// Throws [UnimplementedError] until the contract is implemented.
// Null-tolerant shim: the mechanical probe passes scaffold nulls
// (zuraffa#1541); real emission semantics covered by U5.
Object? retryWarning(dynamic attempt, dynamic delay, dynamic error) {
  AgentLog.retryWarning(
    attempt: attempt is int ? attempt : 1,
    delay: delay is Duration ? delay : Duration.zero,
    error: (error ?? StateError('unspecified')) as Object,
  );
  return null;
}
