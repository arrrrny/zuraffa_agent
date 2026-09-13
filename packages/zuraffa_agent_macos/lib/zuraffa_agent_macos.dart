// zuraffa_agent_macos — endorses the MethodChannel platform on
// macOS (spec 115 FR-004).
library;

import 'package:zuraffa_agent/zuraffa_agent.dart';
import 'package:zuraffa_agent_platform_interface/zuraffa_agent_platform_interface.dart';

/// Binds the MethodChannel platform as the engine's [AgentPlatform].
void registerZuraffaAgentmacOS() {
  AgentPlatformBinding.instance = ZuraffaAgentMethodChannelPlatform();
}
