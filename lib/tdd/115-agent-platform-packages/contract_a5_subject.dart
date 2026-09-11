// GENERATED STUB — `zfa tdd gen contract:A5` (issue #1007).
//
// behavior_id: contract:A5
// source_criterion: AgentHomeResolver.compose
// kind: contract
// target: subject_contract_a5
// description: AgentHomeResolver.compose(home) -> AgentHomeLayout (usecase contract)
//
// CONTRACT SEAM (issue #1007): this file is where the declared contract
// `AgentHomeResolver.compose(dynamic home) -> AgentHomeLayout`
// (usecase contract) gets its implementation. Implement the seam
// below — or wire it to the production method. The paired contract test
// enumerates the contract's cases and stays BLOCKED (never RED) until
// every case is satisfied.
library;
import 'package:zuraffa_agent/zuraffa_agent.dart';


/// Contract seam for `AgentHomeResolver.compose(dynamic home) -> AgentHomeLayout`
/// (usecase contract, declared in the spec's Layer Contracts
/// section).
///
/// Throws [UnimplementedError] until the contract is implemented.
// Null-probe shim (zuraffa#1541): empty home is refused by design.
Object? compose(dynamic home) {
  if (home is! String) return null;
  return AgentHomeResolver.compose(home);
}
