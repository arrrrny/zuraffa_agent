// Certified fake (spec 115 US2/US3): in-memory secure store + fixed
// home, with a call log for assertions. Mirrors the `zfa tdd fake`
// pattern for platform channels (issue #831).

import 'package:zuraffa_agent/zuraffa_agent.dart';

/// The observed calls, as (method, args) pairs.
final class AgentPlatformFake implements AgentPlatform {
  /// The home reported by [getAgentHome].
  final String? home;

  /// The backing secure store.
  final Map<String, String> store = {};

  /// Every observed call: 'getAgentHome' / 'secureRead:key' /
  /// 'secureWrite:key' / 'secureDelete:key'.
  final List<String> calls = [];

  AgentPlatformFake({this.home = '/support'});

  @override
  Future<String?> getAgentHome() async {
    calls.add('getAgentHome');
    return home;
  }

  @override
  Future<String?> secureRead(String key) async {
    calls.add('secureRead:$key');
    return store[key];
  }

  @override
  Future<void> secureWrite(String key, String value) async {
    calls.add('secureWrite:$key');
    store[key] = value;
  }

  @override
  Future<void> secureDelete(String key) async {
    calls.add('secureDelete:$key');
    store.remove(key);
  }
}
