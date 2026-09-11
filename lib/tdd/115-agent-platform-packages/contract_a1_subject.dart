// GENERATED STUB — hand-wired contract seam (spec 115 contract:A1).
// ignore_for_file: non_constant_identifier_names
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

/// Null-probe tolerant (zuraffa#1541); U1 covers the seam behavior.
Future<String?> getAgentHome() async {
  final fake = _LocalFake();
  return fake.home;
}
