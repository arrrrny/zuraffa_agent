// GENERATED STUB — `zfa tdd gen contract:A3` (issue #1007).
//
// behavior_id: contract:A3
// source_criterion: AgentPlatform.secureWrite
// kind: contract
// target: subject_contract_a3
// description: AgentPlatform.secureWrite(key, value) -> Future<void> (usecase contract)
//
// CONTRACT SEAM (issue #1007): this file is where the declared contract
// `AgentPlatform.secureWrite(dynamic key, dynamic value) -> Future<void>`
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
  Future<void> secureWrite(String key, String value) async => store[key] = value;
  @override
  Future<void> secureDelete(String key) async => store.remove(key);
}



/// Contract seam for `AgentPlatform.secureWrite(dynamic key, dynamic value) -> Future<void>`
/// (usecase contract, declared in the spec's Layer Contracts
/// section).
///
/// Throws [UnimplementedError] until the contract is implemented.
// Null-probe shim (zuraffa#1541).
Future<void> secureWrite(dynamic key, dynamic value) async {
  if (key is! String || value is! String) return;
  final fake = _LocalFake();
  await fake.secureWrite(key, value);
}
