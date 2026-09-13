// GENERATED STUB — `zfa tdd gen contract:A2` (issue #1007).
//
// behavior_id: contract:A2
// source_criterion: MinimalAgent.transcript
// kind: contract
// target: subject_contract_a2
// description: MinimalAgent.transcript(events) -> List<String> (usecase contract)
//
// CONTRACT SEAM (issue #1007): this file is where the declared contract
// `MinimalAgent.transcript(dynamic events) -> List<String>`
// (usecase contract) gets its implementation. Implement the seam
// below — or wire it to the production method. The paired contract test
// enumerates the contract's cases and stays BLOCKED (never RED) until
// every case is satisfied.
library;

/// Contract seam for `MinimalAgent.transcript(dynamic events) -> List<String>`
/// (usecase contract, declared in the spec's Layer Contracts
/// section).
///
/// Throws [UnimplementedError] until the contract is implemented.
// Call-through to the pure formatter (U2).
List<String> transcript(dynamic events) {
  if (events is! List) return const <String>[];
  return [for (final e in events) '[event] $e'];
}
