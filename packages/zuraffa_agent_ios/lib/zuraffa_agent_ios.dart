// zuraffa_agent_ios — endorses the MethodChannel platform on
// iOS (spec 115 FR-004).
library;

import 'package:zuraffa_agent/zuraffa_agent.dart';
import 'package:zuraffa_agent_platform_interface/zuraffa_agent_platform_interface.dart';

/// Binds the MethodChannel platform as the engine's [AgentPlatform].
void registerZuraffaAgentiOS() {
  AgentPlatformBinding.instance = ZuraffaAgentMethodChannelPlatform();
}
