// GENERATED STUB — `zfa tdd gen contract:A8` (issue #1007).
//
// behavior_id: contract:A8
// source_criterion: AgentLog.install
// kind: contract
// target: subject_contract_a8
// description: AgentLog.install(level, onRecord) -> void (usecase contract)
//
// CONTRACT SEAM (issue #1007): this file is where the declared contract
// `AgentLog.install(dynamic level, dynamic onRecord) -> void`
// (usecase contract) gets its implementation. Implement the seam
// below — or wire it to the production method. The paired contract test
// enumerates the contract's cases and stays BLOCKED (never RED) until
// every case is satisfied.
library;

import 'package:logging/logging.dart';

import 'package:zuraffa_agent/src/logging/agent_log.dart';

/// Contract seam for `AgentLog.install(dynamic level, dynamic onRecord) -> void`
/// (usecase contract, declared in the spec's Layer Contracts
/// section).
///
/// Throws [UnimplementedError] until the contract is implemented.
// Null-tolerant shim: the mechanical probe passes a scaffold null
// (zuraffa#1541); real install semantics covered by U3. The seam keeps
// the generated `Object?` surface; the void call result is discarded.
Object? install(dynamic level, dynamic onRecord) {
  ZuraffaLogging.install(
    level: level is Level ? level : Level.ALL,
    onRecord: onRecord is void Function(LogRecord)? ? onRecord : null,
  );
  return null;
}
