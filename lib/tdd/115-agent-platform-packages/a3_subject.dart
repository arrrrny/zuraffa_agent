// GENERATED STUB — hand-stepped (spec 115 A3): secure round-trip
// through the bound seam (a fake is bound by the test).
// ignore_for_file: non_constant_identifier_names
library;

import 'package:zuraffa_agent/zuraffa_agent.dart';

Future<List<String?>> subject_a3() async {
  final before = await AgentPlatformBinding.instance.secureRead('openai');
  await AgentPlatformBinding.instance.secureWrite('openai', 'sk-live');
  final written = await AgentPlatformBinding.instance.secureRead('openai');
  await AgentPlatformBinding.instance.secureDelete('openai');
  final after = await AgentPlatformBinding.instance.secureRead('openai');
  return [before, written, after];
}
