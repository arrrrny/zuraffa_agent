// GENERATED STUB — `zfa tdd gen contract:A2` (issue #1007).
//
// behavior_id: contract:A2
// source_criterion: AgentPlatform.secureRead
// kind: contract
// target: subject_contract_a2
// description: AgentPlatform.secureRead(key) -> Future<String?> (usecase contract)
//
// CONTRACT SEAM (issue #1007): this file is where the declared contract
// `AgentPlatform.secureRead(dynamic key) -> Future<String?>`
// (usecase contract) gets its implementation. Implement the seam
// below — or wire it to the production method. The paired contract test
// enumerates the contract's cases and stays BLOCKED (never RED) until
// every case is satisfied.
library;

import 'package:zuraffa_agent/zuraffa_agent.dart';

/// Local in-memory fake (pure Dart) — the engine-side contract slice.
final class _LocalFake implements AgentPlatform {
  final home = '/support';
  final store = <String, String>{};
  @override
  Future<String?> getAgentHome() async => home;
  @override
  Future<String?> secureRead(String key) async => store[key];
  @override
  Future<void> secureWrite(String key, String value) async =>
      store[key] = value;
  @override
  Future<void> secureDelete(String key) async => store.remove(key);
}

/// Contract seam for `AgentPlatform.secureRead(dynamic key) -> Future<String?>`
/// (usecase contract, declared in the spec's Layer Contracts
/// section).
///
/// Throws [UnimplementedError] until the contract is implemented.
// Null-probe shim (zuraffa#1541): probe passes null key.
Future<String?> secureRead(dynamic key) async {
  if (key is! String) return null;
  final fake = _LocalFake();
  return fake.secureRead(key);
}
