// zuraffa_agent_android — endorses the MethodChannel platform on
// Android (spec 115 FR-004). The native plugin answers the channel;
// binding the engine seam is one call.
library;

import 'package:zuraffa_agent/zuraffa_agent.dart';
import 'package:zuraffa_agent_platform_interface/zuraffa_agent_platform_interface.dart';

/// Binds the MethodChannel platform as the engine's [AgentPlatform].
void registerZuraffaAgentAndroid() {
  AgentPlatformBinding.instance = ZuraffaAgentMethodChannelPlatform();
}
